# Travel Manager Application

## 📱 Overview
Travel Manager is a comprehensive iOS application that helps users plan and organize their trips by managing destinations, trips, activities, and expenses. The application provides an intuitive interface built with UIKit and Storyboard, robust data persistence with Core Data, advanced search functionality, and dynamic data retrieval from external APIs.

<p align="center">
  <!-- <img src="destination.png" alt="Destinations List" width="250"/>
   -->
     <img src="screenshots/home.png" alt="Home Screen" width="250"/>
  <img src="screenshots/view destination.png" alt="View Destination" width="250"/>
  <img src="screenshots/add trip.png" alt="Add Trip" width="250"/>
</p>


## ✨ Key Features

### 🏙️ Destination Management
- Create, view, update, and delete travel destinations
  <img src="screenshots/add destination.png" alt="Add Destination" width="250"/>
- Store destination details: city, country, and picture
- Prevent deletion of destinations linked to existing trips
- Fetch destination data dynamically from API
- Manage destination images with UIImagePickerController

### 🧳 Trip Management
- Create trips with start/end dates associated with destinations
  <img src="screenshots/add trip.png" alt="Add Trip" width="250"/>
- Update trip details (title, dates) with validation
- Prevent deletion of trips with linked activities or expenses
- View all trips in an organized list with sorting options

### 🎯 Activity Planning
- Schedule activities for specific trips with date, time, and location
  <img src="screenshots/add activity.png" alt="Add Activity" width="250"/>
- Update activity details with validation
- Prevent deletion of activities scheduled in the past
- View all activities for each trip in chronological order

### 💰 Expense Tracking
- Record expenses for trips with amount and date
  <img src="screenshots/add expense.png" alt="Add Expense" width="250"/>
- Update expense details with validation
- Prevent deletion of expenses older than 30 days
- View expense summaries and totals for each trip

### 🔍 Search Functionality
Powerful search capabilities across:
- Destination
- Trip
- Activity

<img src="screenshots/search destination.png" alt="Search Destination" width="250"/>  
<img src="screenshots/no result found.png" alt="No Result Found" width="250"/>

### 📱 User Interface
- Clean, intuitive interface built with Storyboard
- Responsive design that adapts to all iPhone models
- Appropriate keyboard types for different input fields
- Automatic keyboard management with input field scrolling

## 🚀 Installation & Setup

### Prerequisites
- Xcode 13.0 or later
- iOS 14.0+ device or simulator

### Getting Started
1. Clone this repository
   ```
   git clone https://github.com/yourusername/travel-manager.git
   cd travel-manager
   ```

2. Open the project in Xcode
   ```
   open TravelManager.xcworkspace
   ```
   or
   ```
   open TravelManager.xcodeproj
   ```

3. Build and run the application on your preferred simulator or device


## 📁 Project Structure

```
TravelManager/
├── AppDelegate.swift
├── ViewController.swift
├── Assets.xcassets/
├── Info.plist
├── LaunchScreen.storyboard
├── Main.storyboard
├── Destination/
│   ├── ViewDestinationTableViewController.swift
│   ├── DestinationViewController.swift
│   ├── AddDestinationViewController.swift
│   ├── UpdateDestinationViewController.swift
│   └── DeleteDestinationViewController.swift
├── Trip/
│   ├── ViewTripTableViewController.swift
│   ├── TripViewController.swift
│   ├── AddTripViewController.swift
│   ├── UpdateTripViewController.swift
│   └── DeleteTripViewController.swift
├── Activity/
│   ├── ViewActivityTableViewController.swift
│   ├── ActivityViewController.swift
│   ├── AddActivityViewController.swift
│   ├── UpdateActivityViewController.swift
│   └── DeleteActivityViewController.swift
├── Expense/
│   ├── ViewExpenseTableViewController.swift
│   ├── ExpenseViewController.swift
│   ├── AddExpenseViewController.swift
│   ├── UpdateExpenseViewController.swift
│   └── DeleteExpenseViewController.swift
└── APIModels/
    ├── APIDestination.swift
    └── TripAPIModel.swift
```

## 🔧 Technical Details

### Technology Stack
- **Language**: Swift 5
- **iOS Target**: iOS 14.0+
- **UI Framework**: UIKit with Storyboard
- **Persistence**: Core Data/SQLite
- **Networking**: URLSession for API requests
- **Image Handling**: UIImagePickerController

### Architecture
The application follows the Model-View-Controller (MVC) architecture:
- **Models**: Core Data entities for Destination, Trip, Activity, and Expense
- **Views**: Storyboard-based UI with custom table view cells
- **Controllers**: View controllers for each screen managing business logic

### Data Flow

1. API data retrieval → Data parsing → Core Data storage
2. User interaction → Business logic validation → Core Data update
3. Core Data queries → UI updates

## 📲 Screens & Navigation Flow

### Main Navigation Flow
The application uses a hierarchical navigation structure:

Destinations List → Trip List → Trip Details
                              ↓
                    Activities & Expenses Tabs

### Screen Details
1. **Destinations Screen**
   - Displays all destinations with images
   - Add/Edit/Delete functionality
   - Search capability

2. **Trips Screen**
   - Displays trips for selected destination
   - Add/Edit/Delete functionality
   - Search capability

3. **Trip Details Screen**
   - Tabbed interface for Activities and Expenses
   - Trip summary information
   - Navigation to add/edit activities and expenses

4. **Add/Edit Screens**
   - Form-based input for each entity
   - Validation with error messaging
   - Date pickers and appropriate keyboard types


## 💻 Implementation Highlights


### Core Data Schema
The Core Data model maintains relationships between entities:
- A Destination has many Trips (one-to-many)
- A Trip has many Activities (one-to-many)
- A Trip has many Expenses (one-to-many)


### Responsive UI
Auto-layout constraints ensure proper display across all iPhone models:
- Stack views for flexible content arrangement
- Proportional constraints for adaptive sizing
- Scroll views to accommodate varying content sizes


## ✅ Requirements Checklist
- [x] Storyboard-based UI with segues for navigation
- [x] CRUD operations for all entities (Destination, Trip, Activity, Expense)
- [x] Data validation and meaningful error handling
- [x] Comprehensive search functionality
- [x] Data persistence with Core Data/SQLite
- [x] Dynamic data retrieval from APIs
- [x] Image handling for destinations
- [x] Responsive design for various iPhone models
- [x] Appropriate keyboard types and keyboard management
- [x] No crashes with robust error handling


## 🛠️ Additional Development Notes
- Data model designed to maintain relationships between entities
- Error handling implemented throughout the application
- API integration with proper parsing (XML or JSON)
- Core Data/SQLite used for efficient data storage
- Responsive UI with auto-layout support for various screen sizes
