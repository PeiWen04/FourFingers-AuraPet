# Admin System Documentation

## Overview
The admin system provides comprehensive management capabilities for AuraPet, including user management, activity tracking, feedback resolution, and announcement broadcasting.

## Features

### 1. Admin Authentication
- **Admin Email**: `admin@gmail.com`
- When this email logs in, the system automatically redirects to the admin dashboard
- Activity tracking is also enabled for admin accounts

### 2. User Management
Located in: `lib/pages/admin/user_management_page.dart`

**Features:**
- View all users with their details:
  - Avatar (from Firestore, not Firebase Storage)
  - Username
  - Email
  - Register Date
  - Last Active timestamp
  - Active Today status (green/grey icon)
- **Add New User**: Create Firebase Authentication accounts with username, email, and password
- **Reset Username**: Change a user's display name
- **Reset Email**: Update user's email (requires re-login)
- **Reset Password**: Send password reset email to user

### 3. Activity Tracking
Located in: `lib/services/admin_service.dart`

**Automatic Tracking:**
- Tracks user activity on every login
- Updates `lastActive` timestamp
- Sets `activeToday` flag to `true`
- Logs session in `activity_logs/{dateKey}` subcollection

**Activity Logs Structure:**
```
User-Module/{userId}/activity_logs/{YYYY-MM-DD}
  - sessionCount: number of sessions today
  - sessions: array of timestamps
```

**Admin Dashboard Stats:**
- Total Users Count
- Active Users Today (users with activeToday=true)
- New Feedbacks (unsolved count)

### 4. Feedback Management
Located in: `lib/pages/admin/feedback_management_page.dart`

**Features:**
- View all feedback from all users (using collectionGroup query)
- See user avatar, name, rating, feedback text, and evidence images
- Status management: Unsolved, Ongoing, Resolved
- **Resolve & Notify**: Special button for resolved feedback
  - Creates a personalized announcement for the user
  - Marks feedback as resolved
  - User sees response in their Announcements section

**Resolve Dialog:**
- Shows original feedback text
- Allows admin to write custom response
- Automatically creates announcement with title and message
- Real-time notification to user

### 5. Announcement Management
Located in: `lib/pages/admin/announcement_management_page.dart`

**Broadcast Announcements:**
- Create announcements for all users
- Fields:
  - Title
  - Message
  - Type: info, success, or feedback
- Announcements appear in all users' Announcements collection

**Types:**
- `info`: General information
- `success`: Positive updates
- `feedback`: Feedback responses (also created via Resolve & Notify)

### 6. Admin Dashboard
Located in: `lib/pages/admin/admin_dashboard_page.dart`

**Navigation Rail:**
1. Dashboard - Overview with stats and charts
2. User Management - User CRUD operations
3. Content Management - (existing feature)
4. Feedback Management - Handle user feedback
5. Announcements - Broadcast messages

**Dashboard Stats (Real-time):**
- Total Users
- Active Users Today
- New Feedbacks count
- Mood trends charts
- Content engagement charts

## Firebase Structure

### User Document
```
User-Module/{userId}
  - username: string
  - email: string
  - avatar: string (asset path)
  - createdAt: timestamp
  - lastActive: timestamp
  - activeToday: boolean
```

### Activity Logs Subcollection
```
User-Module/{userId}/activity_logs/{YYYY-MM-DD}
  - sessionCount: number
  - sessions: timestamp[]
  - lastUpdated: timestamp
```

### Announcements Subcollection
```
User-Module/{userId}/Announcements/{announcementId}
  - title: string
  - message: string
  - type: string (info/success/feedback)
  - createdAt: timestamp
  - isRead: boolean
```

### Feedback Subcollection
```
User-Module/{userId}/Feedback/{feedbackId}
  - feedbackText: string
  - rating: number
  - reportedDate: string
  - status: string (Unsolved/Ongoing/Resolved)
  - attachedImage: string (optional)
```

## Admin Service Methods

### User Management
- `getAllUsers()` - Returns list of all users with details
- `createNewUser(email, password, username)` - Create new user account
- `resetUsername(userId, newUsername)` - Update username
- `resetEmail(userId, newEmail)` - Update email (requires re-auth)
- `sendPasswordResetEmail(email)` - Send password reset link

### Activity Tracking
- `trackUserActivity(userId)` - Log user session
- `getActiveUsersToday()` - Count users active today
- `getUserActivityData(userId, days)` - Get activity history for graphs
- `resetActiveTodayFlags()` - Daily reset utility (run via cron/scheduler)

### Announcements
- `createAnnouncementForAll(title, message, type)` - Broadcast to all users
- `resolveFeedbackAndNotify(userId, feedbackId, title, message)` - Resolve feedback + create announcement

### Analytics
- `getTotalUsersCount()` - Total registered users

## Usage Examples

### Track User Login
```dart
final userId = FirebaseAuth.instance.currentUser?.uid;
if (userId != null) {
  await AdminService().trackUserActivity(userId);
}
```

### Create Announcement
```dart
await AdminService().createAnnouncementForAll(
  title: 'New Feature Released',
  message: 'Check out our new mindfulness exercises!',
  type: 'info',
);
```

### Resolve Feedback
```dart
await AdminService().resolveFeedbackAndNotify(
  userId: 'user123',
  feedbackId: 'feedback456',
  title: 'Feedback Response',
  message: 'Thank you for your feedback. We have fixed the issue.',
);
```

## Daily Maintenance

### Reset Active Today Flags
Should be run daily (e.g., at midnight):
```dart
await AdminService().resetActiveTodayFlags();
```

This resets all `activeToday` flags to false so the next day's tracking is accurate.

## Future Enhancements

### Activity Graphs
- Use `getUserActivityData(userId, days)` to create line/bar charts
- Show session trends over time
- Compare user engagement metrics

### Advanced Analytics
- Average session duration
- Most active times of day
- User retention metrics
- Feature usage statistics

### Bulk Operations
- Bulk user management
- Scheduled announcements
- User segmentation for targeted announcements

## Security Notes

1. **Admin Access**: Only `admin@gmail.com` can access admin dashboard
2. **Password Reset**: Sends email, doesn't directly change passwords
3. **Email Updates**: Requires user to re-login with new email
4. **Activity Logs**: Stored in user's subcollection for privacy

## Testing Checklist

- [ ] Login as admin@gmail.com redirects to admin dashboard
- [ ] User list shows all users with correct data
- [ ] Add new user creates Firebase Auth + Firestore document
- [ ] Reset username/email/password works correctly
- [ ] Active users today count is accurate
- [ ] Feedback resolution creates announcement
- [ ] Broadcast announcements appear for all users
- [ ] Activity tracking updates on login
- [ ] Dashboard stats are real-time

## Support

For issues or questions about the admin system, contact the development team.
