# Prompt For BBH Beautiful Body & Health Application 

_Use this file to draft long prompts, new feature requests, or complex instructions. Once you are ready, you can just tell Antigravity:_ **"Please read `prompt.md` and implement the features requested there."**

- **Specific Rules or Constraints:** 
- All new features must be under the i18n feature


## General Definitions
- Look & feel and UX must be really professional. I expect the best of AI to solve this!!
- Transitions between screens
- i18n applyed for all labels used in the App
	- Texts in examples inside the fields MUST be translated too.
- Only one main bar at the very upper part of the screen. Please validate this cause it is having two in some places
## Screen navigation
- **Objective:** define the way the screens are being connected among themselves in the system
- **Screen Definitions:**
- "Welcome Screen": Super prof look and feel workout screen -> "Profile Screen" This can be accessed from any screen (It is part of the main upper bar): Details related to the user
	- **"Workout Screen"**
	  Main screen related to Workout
		- Menu option to Track Session
		- Menu option to Routine definition
		- Menu option to Tracked sessions
	- **"Health Screen"**
	  Main screen related to Health
		- Menu option to Weight Tracking

## Routine data relationship
- **Objective:** relationsheep between data structures 
	- DONT WORRY IF DATASTRUCTURES ARE NOT BACKWARD COMPATIBLE.
- A Routine HAS one or more Routine´s days
- A RoutineDay HAS one or more Exercises
- An Exercise has a number of sets (3 by default) Always greather than 1 
- A RoutineTracking HAS a Date AND one Routine Day (Not the Whole routine). One defined by the user, he/she must add the weight used for each exercise related to the selected routine day

## System data structures:
- **Objective:** definition of internal structures to a better understanding of expected fields, datatypes and validations.
   
- Routne
{
 Name: text. Unique identifier;
 Main objetive: short text explaining the main objective of this Routine. 
 Description: text. Expected result for the person that uses it;
 RoutineDays: At least one or more;
 }

- Exercise
{
 sequence: auto defined value. It is related to the RoutineDay. First exercise is 1, second is 2 .... etc;
 title: description that represents the Exercise;
 description: details about the exercise, how it should be eperformed;
 pictures: one or more pictures that shows the correct way to perform the exercise; (OPTIONAL)
 youtube link: lint to a youtube video that shows the correct way to perform the exercise; (OPTIONAL)
 sets: number of times to perform the exercise;
 restTime: time to rest between sets.
}

- RoutineDay 
{
 Day: Automatic sequence for each Day added to the Routine;
 Exercises: One or more Excercises related to this RoutineDay
  
}

-RoutineTracking

{
 date: tracking date;
 Routine: Selected by the user from available ones;
 RoutineDay: Selected by the user among the ones that belongs to the Routine above.
 Exercises: Selected by the user among the ones that belongs to the day above.
	- For each Exercise:
	 {
	   weight used: number;
	   Notes: notes related to the tracking. (Optional)
	   finished: boolean. Indicates that the exercise was finished
	 }
 state: State of the tracking: STARTED | FINISHED 
 percentage: percent of the routine finished (Read Only)
}
-- The unique key in order to persist and fetch data is date,Routine, RoutineDay

 
## WorkoutTracking screen Details
### ** MUST be really user frendly the way to fill out this data!!!! ** 
- The user can watch the Youtube video associated to the exercise
  - IT MUST work for a real Android device
- The user can see the pictures associated to the exercise. 
	- Implement a friendly mode to see the pictures associated to the exercise. 
		- A carousel navigation mode should be activated when more than one picture is associated.
- The user must add the weight used in the exercise
- Optional: The user can add observations (Notes)
- This must be persisted and edited when the user needs it
- When the day is showed Add the name between "()"
- A check box for an exercise in order to indicate that the exercise was performed. 
-- At least the weight must be informed in order to finish an exercise.
- percentage is calculated as: number of exercises finished / number of exercises for the selected day * 100
- Countdown Timer functionality:
	- Besides the time to rest add a button that represents a clock UI professional please!
		- When pressed a countdown timer appears as a popup and starts to count down the remainig time to finish the time to rest takin as initial time the defined in the exercise. 
	- Once reached perform a really friendly song as a remainder that it finished and close the popup
	- The popup can be cancelled if the user desires this
### Rules for the management of the state
- Only one WorkoutTracking register can be on state STARTED per ROUTINE
	- In case the routine is opened by the user AND it already has a routine is in state started, instead of creating a new one, just open the started one to be edited.
- The user must confirm that he has finished the Tracking routine, confirming it with a special action 
- It is on state STARTED when the user quits from the tracking screen, and the used didnt confirmed that it was finished 
	- Save progress button must save progress and go back to the orevious screen (Change label to save progress and close)
- When the user quits from WorkoutTracking screen, the system must:
	-- persist it
	-- return to the previous screen


 
## RoutineDefinition screen Details: 
### ** MUST be really user frendly the way to fill out this data!!!! ** 
- Allow a user to Create, Read, Update and Delete of Routines and Exercises 
	- Update of a Routine definition cant be performed. PLEASE Implement it
	- Reading of a routine in order to see details and make adjustments. PLEASE implement it.
	- Routines or Exercises that already were used at least once in tracking will be warned that data track will be lost in case it is deleted.
		- remove any related data to tracking in order to maintain consistency
	- About the Exercises
		- Allow to be removed 
		- Allow to be updated
		- For pictures use a picture chooser from galery.
			- It must be compatible with png, jpg, gif file formats
			- It must work for any final platform
		- Define the time to rest as a decimal datatype with one decimal place. Rest time (minutes). 
	
## Tracked sessions screen Details:
### ** MUST be really user frendly the way to fill out this data!!!! **
- **Objective:** Capability to query and see all the past tracked workout sessions
- **Key Details:**
	- Functionality to see ALL past workout sessions
	- graphics showing progression in weights over the time
		- This progression must be comparing the exaclty same exercise that belongs to the routine and specific day
	- graphics showing days in week and in last 30 days with workout sessions
	
## Profile and  configuration screen Details:
- **Objective:** Profile: Identify yourself and get more info and gain access to other systems in order to interoperate
	- Allow the user to export all the structures 
		- maintain the structures exported in a normalized way. Use IDs in order to mantain relationship2:
			- Routines
				- For each record,  mantain here the IDs referencing to the Workout Days as an array form.
			- Workout Days
				- For each record, mantain here the IDs referencing to the Exercises as an array form.
				- Avoid link to the Routine.
			- Exercises 
				- Avoid a link to any other structure from this entity.
			- Workout tracking
	- Allow the user to import data 		
- **Objective:** Configuration: Capability to select the unit measure managed by the system
- **Key Details:**
  - From profile menu add a new entry called "Weight Unit" (Just after language) 
  - Let the user select between Kilos and Pounds (DONT APPLY ANY CONVERTION JUST LEAVE THE VALUES RAW AS IS)
  - The selected one will be used in the whole App when weights are shown

## Weight screen Details:
- **Objective:** Show a graph with the Weights over time
- **Key Details:**
  - On Weight tracking Screen add a graph showing Weight progression over time. This is generated using the weight filled in by the user. 
  - Only show the date in the x axis when we have a plot related in Y axis
  - Dont let te user add a weight for a given date more than once
  
 
  
