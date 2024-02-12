/**
* Name: asgmt2_base
* Based on the internal empty template. 
* Author: Zhinan Gao && Jinyao Zhou
* Tags: 
*/


model asgmt2_base

global {
	int nGuest <- 10;
	int nStore <- 4;
	int nAuctioneers <- 1;

	
	point infoCenterLoc <- {50,50};
	point foodStoreLoc1 <- {25,50};
	point foodStoreLoc2 <- {75,50};
	point drinkStoreLoc1 <- {50,25};
	point drinkStoreLoc2 <- {50,75};
	
	point AuctioneerLoc1 <- {60,75};
	point AuctioneerLoc2 <- {60,50};
	point AuctioneerLoc3 <- {60,25};
	
	
	init {
		create Store with: (storetype: 'foodStore' , location: foodStoreLoc1 ) ;
		create Store with: (storetype: 'foodStore' , location: foodStoreLoc2 ) ;
		create Store with: (storetype: 'drinkStore', location: drinkStoreLoc1 ) ;
		create Store with: (storetype: 'drinkStore', location: drinkStoreLoc2 ) ;
		
		create infoCenter with: (location: infoCenterLoc);
		create Guest number:nGuest;
		//create JapaneseAuctioneer with: (location: AuctioneerLoc1);
		create DutchAuctioneer with: (location: AuctioneerLoc2);
		//create FPSBAuction with: (location: AuctioneerLoc3);
		
	}
}

species DutchAuctioneer skills: [fipa] {
	list<Guest> attendees <- [];
	
	float price <- 1000.0;
	float minPrice <- 50.0;
	int item <- 1; 
	bool isAuctionOngoing <- false;
	bool check <- false;
	int counter <-0;
	//?1
	reflex initiate_auction when: (time = 50 and counter=0) {
		write("The participants are: " + attendees);
		isAuctionOngoing <- true;
		check <- true;
		write("The auction has begun, starting price is: " + price);
		write("Minimum price is: " + minPrice);
		
		loop p over: attendees//?2
		{
			//inform start of auction
			do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction will now begin']);
			
		}
		
		write('(Time ' + time + '): ' + name + ' sends a cfp message to all participants');
		do start_conversation to: list(Guest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
	
		}
	
	
	reflex receive_refuse_messages when: empty(proposes) and !empty(refuses) and isAuctionOngoing {
		write  name + ' receives refuse messages';
	
		
			price <- price* 0.98;
			do start_conversation to: list(Guest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price];
	}
	
	reflex receive_buyer_proposal when : !empty(proposes) and isAuctionOngoing{
		write name + 'receives buy messages: ' + proposes;
		message buyerMessage <- proposes at 0; 
		do accept_proposal message: buyerMessage contents:['Congratulations!'];
		
		write  '\n'+ "---------------------RESULT_2---------------------" ;
		write "Dutch Auction complete! winner: " + buyerMessage.sender;
		write "------------------------------------------------" + '\n';
		isAuctionOngoing <- false;
		counter <- counter+ 1;
	}
	
	aspect base {
		draw triangle(6) color: #black;
		
		}
}

species JapaneseAuctioneer skills: [fipa] {
	
	list<Guest> attendees <- [];
	
	float price <- 500.0;
	float minPrice <- 50.0;
	int item <- 1; 
	bool isAuctionOngoing <- false;
	bool check <- false;
	//?1
	reflex initiate_auction when: (time = 1 and isAuctionOngoing=false) {
		write("The participants are: " + attendees);
		isAuctionOngoing <- true;
		check <- true;
		write("The auction has begun, starting price is: " + price);
		write("Minimum price is: " + minPrice);
		
		loop p over: attendees//?2
		{
			//inform start of auction
			do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction will now begin']);
			
		}
		
		write('(Time ' + time + '): ' + name + ' sends a cfp message to all participants');
		do start_conversation to: list(Guest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
	
		}
	
	
	reflex receive_refuse_messages when: empty(proposes) and !empty(refuses) and isAuctionOngoing {
		write  name + ' receives refuse messages';
		
		loop r over: refuses {
			write '\t' + name + ' refuse from: ' + r.sender;
		
		}
		}
	
	reflex receive_buyer_proposal when : !empty(proposes){
		write name + ' receives buy messages: ' + proposes;
		
		if length(proposes) > 1 {
			loop r over: proposes {
				write '\t' + name + ' sends new cfp to: ' + r.sender;
				do reject_proposal message: r contents: ['More than 2 proposal, Auctioneer reject the price:' + price];

			}
			price <- price+50;
			do start_conversation to: list(Guest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price];
		} 
		
		else {
			message buyerMessage <- proposes at 0; 
			do accept_proposal message: buyerMessage contents:[price, 'Congratulations you have won an item!'];
			write  '\n'+ "---------------------RESULT_1---------------------" ;
			write "Japanese Auction complete! winner: " + buyerMessage.sender;
			write "------------------------------------------------" + '\n';
			isAuctionOngoing <- false;
		}
	}
	
	aspect base {
		draw triangle(6) color: #black;
		
		}
}

species FPSBAuction skills:[fipa] {
	bool isAuctionOngoing <- false;
	int currentBid <- 0;
	string currentWinner <- nil;
	message winner <- nil;
	
	reflex initiate_auction when: (time = 75 and isAuctionOngoing=false) {
		write name + ' time to offer your money for sealed bid!!';
			do start_conversation (to: list(Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['Bid For Sealed']);
	}
	
	reflex responsePropose when: (!empty(proposes)){
		loop p over: proposes {
				write name + ' got an offer from ' + p.sender + ' of ' + p.contents[1];
				if(currentBid < int(p.contents[1]))
				{
					currentBid <- int(p.contents[1]);
					currentWinner <- p.sender;
					winner <- p;
				}
			}
			write name + ' bid ended. Sold to ' + currentWinner + ' for: ' + currentBid;
			write  '\n'+ "---------------------RESULT_3---------------------" ;
			write "First-Price Sealed-Bid Auction complete! winner: " + currentWinner;
			write "------------------------------------------------" + '\n';
			do accept_proposal with: (message: winner, contents: ['Item is yours']);
			
	}
	
	aspect base {
		draw triangle(6) color: #black;
		
		}
	
	
}

species Guest skills:[moving, fipa]{
	list<infoCenter> information <- agents of_species infoCenter;
	infoCenter info_center <- information at 0;
	
	DutchAuctioneer  DutchAuctioneer1;
	
	agent target <- nil;
	Store foodStoreMem <- nil;
	Store drinkStoreMem <- nil;
	
	int hunger <- rnd(8000,9000);
	int thrusholdHungry <- 20;
	bool isHungry <- false;
	
	int thirst <- rnd(8000,9000);
	int thrusholdThirsty <- 20;
	bool isThirsty <- false;
	
	bool isBad <- flip(0.2);
	float budget <- rnd(500, 2800) as float;
	
	bool wantToGoAuction <- flip(0.9);
	unknown interestedGenre <- rnd_choice(["A"::0.2,"B"::0.5,"C"::0.3]);
	bool go <- false;
	int participant_in_auction <- 3;
	point auctionlocation;
	
	reflex getAuction {
		hunger <- 1000;
		thirst <- 1000; 
		
		target <- DutchAuctioneer1;
		
		if(location = auctionlocation){
			ask DutchAuctioneer{
				if(isAuctionOngoing = false){
					add myself to: attendees;
				}
				
				
			}
		}
		
	}
		
		
	reflex receive_accept when: !empty(accept_proposals){
		message proposalFromInitiator <- accept_proposals[0];
		write  name + ' receives a accept message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
		
		float price <- float(proposalFromInitiator.contents[0]);
		budget <- budget - price;
		
	}
	
	reflex receive_cfp_from_auctioneer when: !empty(cfps) {
		message proposalFromInitiator <- cfps[0];
		write name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
		
		list msg <- list(proposalFromInitiator.contents);
		int price <- int(msg at 0);
		//write price;
		
		
		if (proposalFromInitiator.contents[0] = 'Bid For Sealed') {
			int budgetlow <- budget -rnd(100);
			do start_conversation (to: proposalFromInitiator.sender, protocol: 'fipa-propose', performative: 'propose', contents: ['This is my offer', budgetlow]);
			target <- nil;
		}
		else if (price <= budget) {
			write '\t' + name + ' accepts price: ' + price + ' budget: ' + budget;
			do propose message: proposalFromInitiator contents: ['Sure, I will buy this Item'];
		}
		else {
			write '\t' + name + ' refuses price: ' + price + ' budget: ' + budget;
			do refuse message: proposalFromInitiator contents: ['Reject proposal'];
		}
		}
	
	
	// Decreases the guest's hunger level randomly and checks if it's below a threshold. 
	reflex getHungry {
		hunger <- hunger- rnd(0,1); 
		isHungry <- hunger < thrusholdHungry;
		if isHungry and target = nil{
			//write("A guest get hungry!");
			if (foodStoreMem != nil) {
				target <- foodStoreMem;
				float distMem <- self.location distance_to (target.location);
				//write "The direct distance to the target with memory is: " + distMem;
				float distNonMem <- self.location distance_to (infoCenterLoc)+ infoCenterLoc distance_to (target.location);
				//write "The distance to the target through info Center is: " + distNonMem;
				//write "The reduced distance to the target is: " + (distNonMem-distMem);
			}
			else {
				target <- info_center;
				//write("Forgot the location and decide to discover new place!");
			}
		
		}
	}
	
	// Decreases the guest's thirst level randomly and checks if it's below a threshold.
	reflex getThirsty {
		thirst <- thirst - rnd(0,1);  
		isThirsty <- thirst < thrusholdThirsty;
		if isThirsty and target = nil{
			//write("A guest get thirsty!");
			if (drinkStoreMem != nil) {
				target <- drinkStoreMem;
				float distMem <- self.location distance_to (target.location);
				//write "The direct distance to the target with memory is: " + distMem;
				float distNonMem <- self.location distance_to (infoCenterLoc)+ infoCenterLoc distance_to (target.location);
				//write "The distance to the target through info Center is: " + distNonMem;
				//write "The reduced distance to the target is: " + (distNonMem-distMem);
			}
			else {
				target <- info_center;
				//write("Forgot the location and decide to discover new place!");
			}
	
		}
	}
	
	// Makes the guest wander if it doesn't have a target.
	reflex beIdle when: target = nil {
		do wander;
	}
	
	//Moves the guest towards its assigned target.
	reflex moveToTarget when: target != nil {
		do goto target:target;
	}
	
	//Handles the actions when the guest reaches its target (info center or store)
	//Remember the location + recover the hanger/thist level
	reflex enterTarget when: target != nil and location distance_to(target.location) = 0{
	
		ask infoCenter at_distance(1) {
			if (myself.hunger < myself.thrusholdHungry and myself.foodStoreMem = nil) {
				Store food <- rndSelectAFoodStore();
				myself.foodStoreMem <- food;
			}
			if (myself.thirst < myself.thrusholdThirsty and myself.drinkStoreMem = nil) {
				Store water <- rndSelectADrinkStore();
				myself.drinkStoreMem <- water;
			}
			myself.target <- nil;
		
		}
		
		ask Store at_distance(1) {
			if (self.storetype = 'foodStore' and myself.isHungry) {
				//write 'A guest had a meal!';
				myself.hunger <- 80;
				myself.isHungry <- false;
				myself.target <- nil;
			}
			else if (self.storetype = 'drinkStore' and myself.isThirsty) {
				//write 'A guest had a drink!';
				myself.thirst <- 80;
				myself.isThirsty <- false;
				myself.target <- nil;
			}
		}
	}
	
	aspect base {
		rgb agentColor <- rgb("green");
		if (isThirsty) {
			agentColor <- rgb("skyblue");
		} else if (isHungry) {
			agentColor <- rgb("pink");
		}	
		draw circle(1) color: isBad ? #red : agentColor;
	}

}

species infoCenter {
	list<Store> storeList <- agents of_species Store;
	list<Store> foodStoreList <- nil;
	list<Store> drinkStoreList <- nil;
	
	
	init {
		loop store over: storeList  {
			if (store.storetype = 'foodStore') {
				foodStoreList <- foodStoreList + store;
			}
			if (store.storetype = 'drinkStore') {
				drinkStoreList <- drinkStoreList + store;
			}
		}
			
	}
	
	
	Store rndSelectAFoodStore {
			int i <- rnd(0, length(foodStoreList) - 1);
			Store test <- foodStoreList at i;
			return test;
		
	}
	
	Store rndSelectADrinkStore {
		int i <- rnd(0, length(drinkStoreList) - 1);
		return drinkStoreList at i;
	}

	aspect base {
		draw rectangle(4, 4) color: #red;
	}
	
}

species Store {
	string storetype <- flip(0.5) ? 'drinkStore' : 'foodStore';
	
	aspect base {
		draw circle(2) color: storetype = 'drinkStore' ? #skyblue : #pink;
	}
	
}


experiment my_test type: gui {
	output {
		display basic {
			species Guest aspect:base;
			species Store aspect:base;
			species infoCenter aspect:base;
			species DutchAuctioneer aspect:base;
			//species JapaneseAuctioneer aspect:base;
			//species FPSBAuction aspect:base;
			

			
		}
	}
}
