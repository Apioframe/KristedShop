return {
  ["Shop-Name"]="", --Your shop name
  ["Description"]="", --Something greething
  ["Owner"]="", --The name of the shop owner
  ["Wallet-Key"]="", --Your wallet privateKey
  ["Wallet-id"]="", --Your wallet address
  ["Wallet-vanity"]="", -- Your wallet's .kst address | PUT IT WITHOUT THE .KST | Leave empty if none
  ["Accept-wallet-id"]=true, -- whether the shop should accept wallet IDs too.
  ["Redstone_Output"]="top", --The redstone output
  ["Self-Id"]="turtle_", --The turtle id of your network
  ["Discord-Webhook"]=false, --Enable if you want discord webhook
  ["Discord-Webhook-URL"]="", --Your discord webhook url here
  ["Theme"]={
    ["Background-Color"]=0x100, --The shop's background color
    ["Text-Color"]=0x800 --The shop's text color
  },
  ["Items"]={ --The items to sell
    {
      ["Name"]="Example", --Some friendly name
      ["Id"]="minecraft:wheat?name=kaka", --The name of the item with optional filter
      ["Price"]=1, --The price / item
      ["Normal_Stock"]=10, -- Not needed if dynamic pricing is off, if it is on, this determines the defaul stock of the item.
                           -- If the stock is higher than the default stock, the price will be lowered. If the stock is lower than the default stock, the price will be raised.
      ["Force-Default-Price"]=false, -- Not needed if dynamic pricing is off, if it is on, this determines whether it should not change the price of this item.
      ["Alias"]="empl" -- The item's price alias
    },
  },
  ["Enable-Dynamic-Pricing"]=false, --dynamic price
  ["Enable-Automatic-Update"]=true, --Enable automatic updates
  ["Version"]="0.5.0-dev-2", --the kristed version, do not change unless you know what you are doing
  ["Decimal-Digits"]=3, -- How many decimal point digits do we want? ie 2 will be max 0.01, 5 will be max 0.00001
  ["branch"]="dev" -- The branch to use for updates
}
