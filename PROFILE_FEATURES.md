# Player Profile Features

## Overview
Comprehensive player profile system with stats display, game history access, and sign-out functionality.

## Features

### Profile Header
- **Avatar Circle**: Displays first letter of player's display name
- **Display Name**: Player's chosen display name in large text
- **Username**: Player's @username in smaller text
- **Email**: Player's registered email address

### Statistics Display

#### Primary Stats (Side by Side)
1. **Total Score** ⭐
   - Cumulative score across all games
   - Icon: Star
   - Color: Teal (#4ECDC4)

2. **Games Played** 🎮
   - Total number of games completed
   - Icon: Games controller
   - Color: Green (#44A08D)

#### Additional Stats (If Available from Backend)
3. **Best Score** 📈
   - Highest score achieved in a single game
   - Icon: Trending up
   - Color: Red (#E74C3C)

4. **Average Score** 📊
   - Average score across all games
   - Icon: Analytics
   - Color: Purple (#9B59B6)

5. **Total Play Time** ⏱️
   - Total time spent playing (in minutes)
   - Icon: Timer
   - Color: Orange (#F39C12)

### Action Buttons

1. **Game History** (Coming Soon)
   - View past game sessions
   - Detailed game statistics
   - Play history timeline

2. **Leaderboard** (Coming Soon)
   - Global rankings
   - Player position
   - Top scores

3. **Sign Out** 🚪
   - Prominent red button at bottom
   - Confirmation dialog before logout
   - Saves progress message

### UI Features

#### App Bar
- **Back Button**: Return to game
- **Refresh Button**: Reload player stats from server
- **Logout Icon**: Quick access to sign out

#### Sign Out Dialog
- **Enhanced Design**: Modern card with icon
- **Warning Message**: "Progress is saved" notification
- **Two Actions**:
  - Cancel (stay signed in)
  - Sign Out (confirm logout)

#### Loading States
- Loading spinner while fetching data
- Disabled refresh button during load
- Smooth transitions

## User Flow

### Accessing Profile
1. In-game, click on player name/avatar indicator
2. Profile screen slides in from right
3. Automatically fetches fresh player data

### Viewing Stats
1. Profile loads with cached player data
2. Fresh data fetched from backend
3. Stats update smoothly when loaded
4. Refresh button available for manual reload

### Signing Out
1. Click "Sign Out" button (bottom or top-right)
2. Confirmation dialog appears
3. Shows reassuring message about saved progress
4. On confirm:
   - Closes profile screen
   - Calls backend sign out endpoint
   - Clears local auth data
   - Returns to login screen

## API Integration

### Endpoints Used
- `GET /players/profile` - Fetch current player data
- `GET /players/stats` - Fetch additional statistics
- `DELETE /players/sign_out.json` - Sign out request

### Data Flow
1. Profile screen initializes with cached player
2. Makes parallel requests for profile and stats
3. Updates UI with fresh data
4. On logout, waits for backend confirmation
5. Clears secure storage
6. Updates auth state

## Error Handling

### Network Errors
- Shows cached data if fresh fetch fails
- Allows manual refresh retry
- Graceful degradation (shows basic stats)

### Logout Errors
- Even if backend fails, clears local auth
- User can always sign out locally
- Prevents stuck authentication states

## Visual Design

### Color Scheme
- Background: Dark navy (#1A1A2E)
- Primary: Teal (#4ECDC4)
- Accent: Various colors for different stats
- Danger: Red for sign out

### Layout
- Gradient header card for player info
- Grid layout for primary stats
- Stacked layout for additional stats
- Clear visual hierarchy

### Accessibility
- High contrast colors
- Large touch targets (16px vertical padding)
- Clear iconography
- Descriptive labels
- Tooltips on action buttons

## Future Enhancements

1. **Edit Profile**
   - Update display name
   - Change avatar/photo
   - Update email/password

2. **Achievements**
   - Badge system
   - Milestone tracking
   - Share achievements

3. **Social Features**
   - Friends list
   - Challenge friends
   - Share scores

4. **Advanced Stats**
   - Charts and graphs
   - Performance trends
   - Detailed analytics

5. **Customization**
   - Theme selection
   - Avatar customization
   - Profile backgrounds

## Technical Notes

### State Management
- Uses `StatefulWidget` for local state
- Fetches from `BackendService`
- Integrates with `AuthStateService`
- Proper loading states

### Navigation
- Modal route (slides from right)
- Back button support
- Programmatic navigation on logout

### Performance
- Caches player data
- Lazy loads stats
- Efficient rebuilds
- Smooth animations




