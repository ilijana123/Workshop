Apartment Listing System 
iOS application for apartment listings with Firebase.
Two types of users: Advertisers and buyers

Advertiser functionalities:
Registration of the advertiser (name/company name of the advertiser)
Adding a listed apartment with details:
Location (with selection)
Square footage
Number of rooms
Price
Contact phone number
Image upload
Functionality for scheduling a visit to the apartment:
The system provides 8 time slots per working day for visits over the next 5 days starting from the current day (which can be manually disabled).

Advertiser functionalities:
For each scheduled visit, a notification is received with details about the buyer (including their phone number).
The advertiser has the ability to accept or decline the visit request.
Time slots for the next day are automatically carried over from the previous day, adding a new fifth day with available slots.
Overview of scheduled visits, including the ID of the apartment being visited.

Buyer functionalities:
Buyer registration (name/company name and phone number)
A table displaying all apartments with basic details and the option to filter by location.
Option to view apartments in a grid format showing only images (selectable via a tab bar).
Viewing detailed information about an apartment, with the ability to schedule a visit (choosing from available time slots).
In the details section, users should be able to swipe left or right to navigate between apartments.
Option to rate each advertiser and apartment (allowed within one day after a completed visit).
