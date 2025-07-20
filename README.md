# Digital Public Bandstand Scheduling System

A comprehensive smart contract system for managing public bandstand operations, including performance bookings, equipment rentals, permits, crowd management, and maintenance coordination.

## System Overview

The Digital Public Bandstand Scheduling system consists of five interconnected smart contracts:

### 1. Performance Booking Contract (`performance-booking.clar`)
- Manages concert and event reservations
- Handles booking slots, performer registration, and event scheduling
- Tracks performance history and ratings

### 2. Sound System Rental Contract (`sound-system-rental.clar`)
- Provides audio equipment rental services
- Manages equipment inventory and availability
- Handles rental payments and equipment condition tracking

### 3. Permit Processing Contract (`permit-processing.clar`)
- Issues permits for amplified music events
- Manages permit applications and approvals
- Tracks compliance and permit history

### 4. Crowd Management Contract (`crowd-management.clar`)
- Coordinates seating arrangements and audience capacity
- Manages safety protocols and emergency procedures
- Tracks attendance and crowd flow

### 5. Maintenance Coordination Contract (`maintenance-coordination.clar`)
- Schedules stage repairs and cleaning
- Manages maintenance requests and work orders
- Tracks facility condition and maintenance history

## Features

- **Decentralized Booking**: Transparent and fair performance scheduling
- **Equipment Management**: Comprehensive audio equipment rental system
- **Permit Automation**: Streamlined permit application and approval process
- **Safety Coordination**: Automated crowd management and safety protocols
- **Maintenance Tracking**: Proactive facility maintenance scheduling

## Contract Architecture

Each contract operates independently while maintaining data consistency across the system. The contracts use native Clarity data types and functions for optimal performance and security.

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Testing

The system includes comprehensive tests using Vitest:

\`\`\`bash
npm test
\`\`\`

## Usage Examples

### Booking a Performance
\`\`\`clarity
(contract-call? .performance-booking book-performance
"Summer Jazz Concert"
u1640995200
u7200
u100)
\`\`\`

### Renting Sound Equipment
\`\`\`clarity
(contract-call? .sound-system-rental rent-equipment
u1
u1640995200
u14400)
\`\`\`

### Applying for Permit
\`\`\`clarity
(contract-call? .permit-processing apply-permit
"Amplified Music Event"
u1640995200
u85)
\`\`\`

## Security Considerations

- All contracts include proper access controls
- Input validation prevents malicious data
- State management ensures data consistency
- Error handling provides clear feedback

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development standards.

## License

This project is licensed under the MIT License.
