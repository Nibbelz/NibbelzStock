# Nibbelz Stock

A World of Warcraft addon for **WoW Forever** that counts every item in your bags, bank and mail on all your characters. Item tooltips show how many the account has and which character holds how many, an overview window lists everything with its auction house value, and a minimum-amount slider shows only what you have plenty of (e.g. at least 100).

English and German.

## Features
- **Tracks bags, bank and mail** of every character on the account. Bags are read all the time, bank and mail when you open them. Mail sent to your own characters counts on them right away.
- **Tooltip**: account total and every character's count, optionally split into bags / bank / mail, plus the AH value per item and for all of them. Option to show only characters of the current realm.
- **Overview**: all items in one sortable list (name, total, bags, bank, mail, AH price, AH value) with search, character and place filters, "Materials only", and a **minimum amount** slider plus a box for an exact number. The total AH value of what's shown is at the top.
- **Sellable only** (on by default): hides soulbound, quest and account-bound items, which also get no AH value.
- **AH prices** from TradeSkillMaster, Auctionator, Auctioneer or NaowhForever (automatic or one fixed source).
- Six window styles, minimap button, addon compartment entry.

## Commands
| Command | What it does |
|---|---|
| `/stock` | Overview |
| `/stock <name>` | Overview searching for `<name>` |
| `/stock options` | Options |
| `/stock minimap` | Minimap button on / off |
| `/stock scan` | Rescan your bags |

## Install
Download the latest release and put the `NibbelzStock` folder into
`World of Warcraft\_forever_\Interface\AddOns`.

Open the bank and the mailbox once on every character so their items are counted.

## Changelog
See [CHANGELOG.md](CHANGELOG.md).

## License
All Rights Reserved. See [LICENSE.txt](LICENSE.txt).
