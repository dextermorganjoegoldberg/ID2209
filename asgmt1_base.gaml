/**
* Name: asgmt1_base
* Based on the internal empty template. 
* Author: Zhinan Gao && Jinyao Zhou
* Tags: 
*/


model asgmt1_base

global {
	int nGuest <- 10;
	int nStore <- 4;
	
	point infoCenterLoc <- {50,50};
	point foodStoreLoc1 <- {25,50};
	point foodStoreLoc2 <- {75,50};
	point drinkStoreLoc1 <- {50,25};
	point drinkStoreLoc2 <- {50,75};
	
	init {
		create Store with: (storetype: 'foodStore' , location: foodStoreLoc1 ) ;
		create Store with: (storetype: 'foodStore' , location: foodStoreLoc2 ) ;
		create Store with: (storetype: 'drinkStore', location: drinkStoreLoc1 ) ;
		create Store with: (storetype: 'drinkStore', location: drinkStoreLoc2 ) ;
		
		create infoCenter with: (location: infoCenterLoc);
		create Guest number:nGuest;
	}
}

species Guest skills:[moving]{
	list<infoCenter> information <- agents of_species infoCenter;
	infoCenter info_center <- information at 0;
	
	
	agent target <- nil;
	
	int hunger <- rnd(30,90);
	int thrusholdHungry <- 20;
	bool isHungry <- false;
	
	int thirst <- rnd(30,90);
	int thrusholdThirsty <- 20;
	bool isThirsty <- false;
	
	
	
	reflex getHungry {
		hunger <- hunger- rnd(0,1); 
		isHungry <- hunger < thrusholdHungry;
		if isHungry and target = nil{
			write("A guest get hungry!");
			target <- info_center;
			}
		
		}
	
	reflex getThirsty {
		thirst <- thirst - rnd(0,1);  
		isThirsty <- thirst < thrusholdThirsty;
		if isThirsty and target = nil{
			write("A guest get thirsty!");
			target <- info_center;
			}
	
		}
	
	reflex beIdle when: target = nil {
		do wander;
	}
	
	reflex moveToTarget when: target != nil {
		do goto target:target;
	}
	
	reflex enterTarget when: target != nil and location distance_to(target.location) = 0{
	
		ask infoCenter at_distance(1) {
			if (myself.hunger < myself.thrusholdHungry) {
				Store food <- rndSelectAFoodStore();
				myself.target <- food;
			}
			if (myself.thirst < myself.thrusholdThirsty) {
				Store water <- rndSelectADrinkStore();
				myself.target <- water;
			}
		
		}
		
		ask Store at_distance(1) {
			if (self.storetype = 'foodStore' and myself.isHungry) {
				write 'A guest had a meal!';
				myself.hunger <- 80;
				myself.isHungry <- false;
				myself.target <- nil;
			}
			else if (self.storetype = 'drinkStore' and myself.isThirsty) {
				write 'A guest had a drink!';
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
		draw circle(1) color: agentColor;
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
		}
	}
}
