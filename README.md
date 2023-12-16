# Description

ConsoleBags is a bag addon that lets you manage your inventory and bank with ease using a controller. It is compatible with ConsolePort, the popular addon that enables controller support for World of Warcraft. You can also use ConsoleBags with a mouse and keyboard, but it is optimized for a controller experience.

With ConsoleBags, you can:
- View your bags and bank in a simple and organized list
- Sort your items by various criteria, such as name, rarity, item level, required level, and sell price
- Perform actions such as equip, use, sell, or delete items with a controller
- See additional information from other addons with Pawn, CanIMogIt, and Scrap icons
- Customize the appearance of your items with Masque support

ConsoleBags is the perfect addon for controller users who want to have more control over their inventory and bank. Download it today and enjoy a new way of playing World of Warcraft!

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
- Moving item from bank > bag... bank doesn't refresh
- Equipping bag update?
- Can't use scrolls?
- Tooltip (backgrounds?) stick around when switching tabs
    - Not sure how to fix this issue
- Selecting a tab with the mouse and then using keybinds tabs from the original location
- Keybinds should disable when in combat

Tech Debt TODOS:
- InventoryFrame & BankFrame are almost identical