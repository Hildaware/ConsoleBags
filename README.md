Data Storage (Cross character, etc.)
- I think we can get away with storing just itemID > link, stackCount, bound
    - ```
        {
            itemId = { link, stackCount, bound }
        }
    ```
- 

Post-MVP:
- Customization
    - Hiding Columns
    - Resizing Columns
    - Resizing Bag Width
- Account-Wide Inventories
    - Save items on logout to db
    - Ability to view all items on account
- Search
    - NBD at the moment, as this is aimed at controllers

BUGS:
- Equipping bag update?
- Can't use scrolls?
- Tooltip (backgrounds?) stick around when switching tabs
    - Not sure how to fix this issue

Tech Debt TODOS:
- InventoryFrame & BankFrame are almost identical