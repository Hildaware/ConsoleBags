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

BUGS:
- Equipping bag update?
- Add missing category icons (keys, etc?)
- Can't use scrolls?
- Randomly we have empty rows after a Gather

Tech Debt TODOS:
- InventoryFrame & BankFrame are almost identical