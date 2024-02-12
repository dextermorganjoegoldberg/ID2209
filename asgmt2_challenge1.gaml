/**
* Name: asgmt2_challenge1
* Based on the internal empty template. 
* Author: Zhinan Gao && Jinyao Zhou
* Tags: 
*/


model Challenge

global{
	int nPeople <- 15;
	int nInfoCenters <- 1;
	int nAuctioneers <- 3;
	list<Auctioneer> list_of_auctioneers <- [];
	list<string> items <- ['CDs', 'clothes', 'toys'];
	list<string> acuType <- ['Dutch', 'English', 'Japanese'];

	init{
		create FestivalGuest number: nPeople
		{
			chosenInfoCenter <- rnd(1,2); 
		}
		
		create FoodStore{location <- {25,50};}
		create FoodStore{location <- {75,50};}
		
		create DrinkStore{location <- {50,25};}
		create DrinkStore{location <- {50,75};}
		
		
		create Auctioneer{location <- {60,75};}
		create Auctioneer{location <- {60,50};}
		create Auctioneer{location <- {60,25};}
		
		create InfoCenter1
		{
			location <- {50,50};
			drinkstoreloc <- {40,50};
			foodstore1loc <- {10,90};
			foodstore2loc <- {10,10};
		}
		create InfoCenter2
		{
			location <- {50,50};
		    drinkstoreloc <- {60,50};
			foodstore1loc <- {90,90};
			foodstore2loc <- {90,10};
		}
	}	
}

species Auctioneer skills: [fipa]{
	
	list<FestivalGuest> attendees <- [];
	int current_price <- rnd(1000,2000);
	int min_price <- rnd(100, 300) ;
	bool auction <- false;
	FestivalGuest winning_guest; 
	bool auction_winner <- false;
	bool update <- false;
	bool check <- false;
	bool auction_announced <- false;
	int item_to_sell <- length(Auctioneer);
	int aucTypeNum <-length(Auctioneer);
	
	string item <- items[item_to_sell];
	string type <- acuType[aucTypeNum];
	
	list<FestivalGuest> myguestlist <- [];
	bool added_to_list <- false;
	
	aspect base{
		rgb agentColor <- rgb("black");
		draw triangle(6) color: agentColor;
		if(self.added_to_list = false){
			add self to: list_of_auctioneers;
			self.added_to_list <- true;
		}
		

	}
	
	reflex announce_auction when: (!empty(self.myguestlist)){
		write("---------------------------------------------------------------------" );
		write(""+ type + " " + self + " announcing auction");
		write("---------------------------------------------------------------------" );
		loop g over: self.myguestlist
		{
			//inform start of auction
			do start_conversation (to :: [g], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['An auction will soon take place, I am selling: ' + self.item, self.item]);
			//remove g from: self.myguestlist;
		}
		self.myguestlist <- [];
	}
	
	reflex initiate_auction when: length(self.attendees) > 2 and self.auction = false{
		write("The participants for the auction of item: " + self.item + " are: " + self.attendees);
		self.auction <- true;
		self.check <- true;
		write("The auction has begun, starting price of item: " + self.item + " is: " + self.current_price);
		write("Minimum price for item: " + self.item + " is: " + self.min_price);
		
		loop p over: self.attendees
		{
			//inform start of auction
			do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction will now begin']);
			
		}
	}
	
	reflex send_message when: self.auction = true and self.auction_winner = false and self.check = true{
		//call for proposals
		do start_conversation with: (to :: attendees, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [self.current_price, self.item]);
		self.check <-false; 
	}
	
	reflex read_message when: (auction = true and !empty(proposes)){
		loop p over: proposes{
			list<unknown> propose_list <- p.contents;
				if (propose_list[0] = true){
					do accept_proposal with: [message :: p, contents :: ['Participants offer accepted']];
					self.winning_guest <- p.sender;
					self.auction_winner <- true;
					self.auction <- false;
					self.update <- false;
					write("\n--------------------------------------------------------------------- ");
					write(""+ type +" " + self +" Annocement: " + self.item + " had sold to " + self.winning_guest + " Auction is now over!");
					write("---------------------------------------------------------------------\n" );
					break;
				}
		}
		if(self.auction_winner = false){
			self.update <- true;
		}
	}
	
	reflex update_price when: (update = true and auction_winner = false){
		self.current_price <- current_price*0.95;
		write ("Updating price, decreased price is now: " + current_price + " of item: " + self.item);
		if(current_price < min_price){
			self.auction <- false;
			loop p over: attendees{
				//inform
				do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction is cancelled']);
			}
			self.attendees <- [];
			write("\n---------------------------------------------------------------------");
			write (""+ type +"Auction cancelled, item: " + self.item + " not sold");
			write("---------------------------------------------------------------------\n" );
		}
		self.check <- true;
		self.update <- false;
	}
	
	reflex found_winner when: auction_winner = true{
		loop p over: attendees{
			//inform the participants of the winner
			do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction is over']);
		}
		attendees <- [];
	} 

}


/* FestivalGuest uses the methods of moving */
species FestivalGuest skills: [fipa,moving]
{
	int participant_in_auction <- 3;
	int chosenInfoCenter; //the info center we will go to
	float hunger <- rnd(1000) max: 1000 update: hunger+rnd(1);
	float thirst <- rnd(1000) max: 1000 update: thirst+rnd(1);
	bool knowledgeOfStore <- false;
	bool decidedPrice <- false;
	point auctionlocation;
	int budget; 
	bool in_auction <- false;
	bool want_to_buy <- false;
	bool go <- false;
	bool decided_auc <- false;
	//int interested;
	//bool interested_in_item <- false;
	int interested <- rnd(length(items)-1);
	bool added_to_guestlist <- false;
	string item;
	Auctioneer messagesender;
	
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("green");
		if (hunger > 500 and thirst > 500) {
			agentColor <- rgb("pink");
		}
		else if (thirst > 500) {
			agentColor <- rgb("pink");
		}
		else if (hunger > 500) {
			agentColor <- rgb("skyblue");
		}
		draw circle(1) color: agentColor;
	}
	
	reflex add_to_guestlist when: participant_in_auction = 3 and added_to_guestlist = false{
		ask list_of_auctioneers[0]{
			add myself to: self.myguestlist;
		}
		ask list_of_auctioneers[1]{
			add myself to: self.myguestlist;
		}
		ask list_of_auctioneers[2]{
			add myself to: self.myguestlist;
		}
		added_to_guestlist <- true;
		//self.interested <- rnd(0,1);
	}
	reflex decide_which_auc when: (!empty(cfps) and self.decided_auc = false and participant_in_auction = 3){
		message item_message <- cfps at 0;
		list<unknown> item_messages <- item_message.contents;
		self.messagesender <- Auctioneer(item_message.sender);
		string item1 <- string(item_messages[1]);
		if(items[self.interested] = item1){
			self.auctionlocation <- messagesender.location;
			self.decided_auc <- true;
			self.item <- item1;
			write("" + self + " is interested in item: " + self.item);
		}
	}
	
	reflex go_to_auction when: (participant_in_auction = 3 and go = false and self.decided_auc = true){
		self.hunger <- 1000.0;
		self.thirst <- 1000.0; 

		self.targetPoint <- self.auctionlocation;
		if(self.location = self.auctionlocation){
			ask messagesender{
				if(self.auction = false){
					add myself to: self.attendees;
					myself.go <- true;
				}
				else{
					myself.targetPoint <- nil;
					myself.participant_in_auction <- 0;
				}
			}
		}
	}
	
	reflex read_message when: (!empty(cfps) and participant_in_auction = 3 and self.decided_auc = true){
		message price_message <- cfps at 0;
		list<unknown> price_messages <- price_message.contents;
		if(string(price_messages[1]) = self.item){
			int price <- int(price_messages[0]);
			if(!(self.decidedPrice)){
				self.budget <- rnd(1000, 1500);
				if(self.budget <= 0){
					self.budget <- 100; 
				}
				write("" + self + " ready to pay: " + self.budget + " for item: " + self.item);
				self.decidedPrice <- true;
			}
			if(self.budget >= price){
				self.want_to_buy <- true;
			}
			//propose an offer
			do propose with: (message: price_message, contents: [self.want_to_buy]);
		}
	}
	
	point targetPoint <- nil;
	reflex beIdle when: targetPoint = nil
	{
		do wander;
	}
	
	/* If targetPoint is not nil (we have a target to go to) we go there */
	reflex moveToTarget when: targetPoint != nil
	{
		do goto target:targetPoint;
	}
	
	//reflex moveToInfoCenter when: (isThirsty or isHungry) and targetPoint = nil {
	reflex moveToInfoCenter when: (hunger > 500 or thirst > 500) and knowledgeOfStore = false {
		//write("Guest moving to info center");
		if(chosenInfoCenter = 1){
			targetPoint <- {10,50};
		}
		else if(chosenInfoCenter = 2)
		{
			targetPoint <- {90,50};
		}
		if(location = {10,50})
		{
			//write("Guest at info center 1");
			if(thirst > 500){
				ask InfoCenter1{
					//write("Guest asks info center 1 for drink store");
					myself.targetPoint <- drinkstoreloc;
					myself.knowledgeOfStore <- true;
					//write("Guest moving to drink store 1");
				}
			}
			if(hunger > 500){
				int randomNumber <- rnd(1,2);
				if(randomNumber = 1){
					ask InfoCenter1{
						//write("Guest asks info center 1 for food store");
						myself.targetPoint <- foodstore1loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 1");
					}
				}
				if(randomNumber = 2){
					ask InfoCenter1{
						//write("Guest asks info center 1 for food store");
						myself.targetPoint <- foodstore2loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 2");
					}
				}
			}
		}
		if(location = {90,50})
		{
			//write("Guest at info center 2");
			if(thirst > 500){
				ask InfoCenter2{
					//write("Guest asks info center 2 for drink store");
					myself.targetPoint <- drinkstoreloc;
					myself.knowledgeOfStore <- true;
					//write("Guest moving to drink store 2");
				}
			}
			if(hunger > 500){
				int randomNumber <- rnd(1,2);
				if(randomNumber = 1){
					ask InfoCenter2{
						//write("Guest asks info center 2 for food store");
						myself.targetPoint <- foodstore1loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 3");
					}
				}
				if(randomNumber = 2){
					ask InfoCenter2{
						//write("Guest asks info center 2 for food store");
						myself.targetPoint <- foodstore2loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 4");
					}
				}
			}
		}
	}
	
	reflex goToStore when: knowledgeOfStore = true{
		do goto target:targetPoint;
	}
	
	
	reflex getDrink when: thirst > 500{
		if(location = {40,50}){
			//write("Guest at drink store 1");
			thirst <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer thirsty");
		}
		if(location = {60,50}){
			//write("Guest at drink store 2");
			thirst <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer thirsty");
		}
	}
	reflex getFood when: hunger > 500{
		if(location = {10,90}){
			//write("Guest at food store 1");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
		if(location = {10,10}){
			//write("Guest at food store 2");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
		if(location = {90,10}){
			//write("Guest at food store 4");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
		if(location = {90,90}){
			//write("Guest at food store 3");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
	}
}

species FoodStore {
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("pink");
		draw circle(2) color: agentColor;
	}
}

species DrinkStore {
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("skyblue");
		draw circle(2) color: agentColor;
	}
}

species InfoCenter1 {
	//Food stores
	point foodstore1loc;
	point foodstore2loc;
	//Drink stores
	point drinkstoreloc;
	
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("red");
		draw square(4) color: agentColor;
	}
}

species InfoCenter2 {
	//Food stores
	point foodstore1loc;
	point foodstore2loc;
	//Drink stores
	point drinkstoreloc;
	
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("red");
		draw square(4) color: agentColor;
	}
}

experiment myExperiment type:gui {
	output {
		display myDisplay {
			//Display the species with the created aspects
			species FestivalGuest aspect:base;
			species FoodStore aspect:base;
			species DrinkStore aspect:base;
			species InfoCenter1 aspect:base;
			species InfoCenter2 aspect:base;
			species Auctioneer aspect:base;
		}
	}
}

