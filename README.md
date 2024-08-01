# Description

ConsoleBags is a bag addon that lets you manage your inventory and bank with ease using a controller. It is compatible with ConsolePort, the popular addon that enables controller support for World of Warcraft. You can also use ConsoleBags with a mouse and keyboard, but it is optimized for a controller experience.

With ConsoleBags, you can:
- View your bags and bank in a simple and organized list
- Sort your items by various criteria, such as name, rarity, item level, required level, and sell price
- Perform actions such as equip, use, sell, or delete items with a controller
- See additional information from other addons with Pawn, CanIMogIt, and Scrap icons
- Customize the appearance of your items with Masque support

ConsoleBags is the perfect addon for controller users who want to have more control over their inventory and bank. Download it today and enjoy a new way of playing World of Warcraft!

# 11.0
- Banks
    - See bug about moving items. It's probably something to do with the frame itself
- Performance
    - Opening bags, etc. can be slow. Can we use SendMessage to do this more async?
    - Is there an event we can read specific to a slot changing? Can we forcibly handle this?

# Post-MVP
- Customization
    - Hiding Columns
    - Resizing Columns
    - Resizing Bag Width
- Account-Wide Inventories
    - Save items on logout to db
    - Ability to view all items on account
- Search
    - NBD at the moment, as this is aimed at controllers

# Bugs
- Moving item from bank > bag... bank doesn't refresh (May be fixed?)
- Equipping bag update?
- Default bag location is not good