# Future Additions (Official Platform Notes)

This page summarizes future-facing items mentioned in the official Hytale Server Manual.

## Server & minigame discovery

A discovery catalogue accessible from the main menu where players can browse and find servers/minigames.

Requirements mentioned:

- adhere to server operator guidelines and community standards
- provide accurate self-rating (powers filtering/parental controls)
- enforcement actions for violations

Player count verification:

- player counts shown in discovery are gathered from client telemetry rather than server-reported data
- servers may still report an unverified player count for users who added the server outside discovery

## Parties

A party system enabling players to group up and stay together across server transfers and queues.

## Integrated payment system

An optional in-client payment gateway for server operators.

## SRV record support

Status in the manual:

- currently unsupported and under evaluation

## First-party API endpoints

Planned endpoints mentioned:

- UUID ↔ Name lookup
- Game version / protocol version
- Player profile
- Server telemetry
- Report
- Payments

Under consideration:

- Global sanctions
- Friends list
- Webhook subscriptions

Design goals mentioned:

- generous rate limits
- authenticated access
- versioned API with deprecation windows
