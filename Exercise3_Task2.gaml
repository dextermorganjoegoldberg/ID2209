/**
* Name: asgmt3_task2
* Based on the internal empty template. 
* Author: Zhinan Gao & Jinyao Zhou
* Tags: 
*/


model asgmt3_task2


global {
    int numberOfPeople <- 40;
    int numberOfStages <- 4;

    init {
        create Guest number:numberOfPeople ;
        create Stage number:numberOfStages;
    }
}

species Guest skills: [fipa, moving] {
    float lightshowWeight <- rnd(0.0, 1.0);
    float speakersWeight <- rnd(0.0, 1.0);
    float bandWeight <- rnd(0.0, 1.0);
    float atmosphereWeight <- rnd(0.0, 1.0);
    float celebrityPerformerWeight <- rnd(0.0, 1.0);
    float interactivityWeight <- rnd(0.0, 1.0);
    bool isWatching <- false;
    
    float actExpiry <- 1.0; 
    
    Act theHeadingTarget <- nil;
    
    reflex changeTarget when: theHeadingTarget != nil {
    	if (time = actExpiry) {
    		theHeadingTarget <- nil;
    	}
    }
    
    
    reflex processReceivedActs when: theHeadingTarget = nil and !empty(informs) {
        write("[" + name + "] Received information from " + length(informs) + " stages on what the acts are");
        
        list<Act> options <- [];
        loop i over: informs {
			Act foundAct <- i.contents[0];
			add foundAct to: options;
        }

        Act bestAct <- nil;
        float bestUtility <- 0;
        write("-----------------------------------------"+name+"--------------------------------------------");
        write("[" + name + "] Preferences are:");
        write(" 1.lightshow = " + lightshowWeight);
        write(" 2.speakers = " + speakersWeight);
        write(" 3.band = " + bandWeight);
        write(" 4.atmosphere = " + atmosphereWeight);
        write(" 5.celebrityPerformer = " + celebrityPerformerWeight);
        write(" 6.interactivity = " + interactivityWeight);
        
    	write("[" + name + "] Utilities of current stages are:");
        loop i over: options {
        	if(!dead(i)){
  				float utility <- 0.0;
            	utility <- utility + (lightshowWeight * i.lightshow);
            	utility <- utility + (speakersWeight * i.speakers);
            	utility <- utility + (bandWeight * i.band);
           		utility <- utility + (atmosphereWeight * i.atmosphere);
            	utility <- utility + (celebrityPerformerWeight * i.celebrityPerformer);
           	 	utility <- utility + (interactivityWeight * i.interactivity);
           		write("" + i + " = " + utility);
        	    if (utility > bestUtility) {
            	    bestUtility <- utility;
              		bestAct <- i;
            }
        	}
            
        }
        theHeadingTarget <- bestAct;
        actExpiry <- theHeadingTarget.expiry;
        write( name + " have chosen act " + bestAct + " with highest utility " + bestUtility);
    }

    reflex queryCurrentActs when: theHeadingTarget = nil {
        do start_conversation to: list(Stage) protocol: 'fipa-query' performative: 'query' contents: ['acts']; 
    }

    
    reflex goToTarget when: theHeadingTarget != nil and (location distance_to (theHeadingTarget.location) > 10) {
    	isWatching <- false;
    	do goto target: theHeadingTarget.location;
    }
    

    reflex setWatchingState when: theHeadingTarget != nil and (location distance_to (theHeadingTarget.location) <= 10 ) {
    	isWatching <- true;
    }
    
    aspect base {
    	rgb agentColor;
    	
    	if isWatching{
    		if (time mod 2)=0{
    		agentColor <- rgb("green");
    		}
    		else{
    		agentColor <- rgb("transparent");
    	}
    	}
    	else{
    		agentColor <- rgb("white");
    	}
		
      	draw circle(2) color: agentColor border: #black;
	}
	
}

species Stage skills: [fipa] {
    Act currentAct <- nil;
    int actDuration <- rnd(30, 40);
    float stagePreperationDelayCounter <- 20;
    

    reflex replyQuery when: !(empty(queries)) {
        loop i over: queries {
            if (i.contents[0] = 'acts') {
                do agree message: i contents: ['I have acts'];
                do inform message: i contents: [currentAct];
            }
        }
    }

    reflex restartStage {
    
        if (currentAct = nil) {
	    	do newAct;
        }
        
        if (currentAct != nil and time >= currentAct.expiry ) {
        	ask currentAct {
        		do die;
        	}
        	currentAct <- nil;
        	
        }
    }
    
    action newAct {
    	create Act returns: createdAct;
    	currentAct <- createdAct[0];
     	currentAct <- currentAct.setLocation(self);
    }

    aspect base {
    	rgb stageColor <- #black;
		draw hexagon(10) at: location color: stageColor;
	}
}

species Act {
	float expiry <- time + rnd(70, 100);
	
    float lightshow <- 0.5 + rnd(0,0.5);
    float speakers <- 0.5 + rnd(0,0.5);
    float band <- 0.5 + rnd(0,0.5);
    float atmosphere <- 0.5 + rnd(0,0.5);
    float celebrityPerformer <- 0.5 + rnd(0,0.5);
    float interactivity <- 0.5 + rnd(0,0.5);
    Stage stage <- nil;
    
    action setLocation(Stage s) type: Act {
    	stage <- s;
    	location <- s.location;
    	return self;
    }

    aspect base {
    	rgb agentColor<- rgb("green");
    
        draw circle(2) color: agentColor;
    }
}

experiment myExperiment type:gui {
	output {
		display myDisplay {
			species Guest aspect:base;
			species Stage aspect:base;
			species Act aspect:base;
		}
	}
}