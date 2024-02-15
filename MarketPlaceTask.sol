// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MarketPlace {
    enum ItemStatus {
        Available,
        Sold,
        Cancelled,
        Disputed,
        Confirmed,
        Completed,
        ResolveDisputed
    }


    event Available(
        uint256 item_id,
        bytes item_name,
        string item_discription,
        uint256 item_price,
        address seller,
        ItemStatus status
    );
    event Sold(
        uint256 item_id,
        uint256 item_qty,
        address buyer,
        ItemStatus status
    );
    event Cancelled(uint256 item_id, address seller, ItemStatus status);
    event Disputed(address buyer, ItemStatus status);
    event Confirmpurchase(address seller, ItemStatus status);
    event resolveDispute(
        uint256 Item_Id,
        ItemStatus status,
        uint256 amount,
        address Seller
    );
    event sellerWithdraw(
        uint256 ItemId,
        ItemStatus status,
        uint256 amount,
        address seller
    );

    address public immutable Admin;

    constructor() {
        Admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == Admin, "Only Admin can call this function");
        _;
    }

    modifier itemExists(uint256 _item_id) {
        require(Items[_item_id].ItemExist, "Item does not exist");
        _;
    }
    modifier itemAvailable(uint256 _itemId) {
        require(
            Items[_itemId].status == ItemStatus.Available,
            "Item is not available"
        );
        _;
    }

    modifier itemNotSold(uint256 _itemId) {
        require(
            Items[_itemId].status != ItemStatus.Sold,
            "Item is already sold"
        );
        _;
    }

    modifier onlyseller(uint256 item_id) {
        require(
            msg.sender == Items[item_id].ItemSeller,
            "Only Seller can call this function"
        );
        _;
    }

    modifier onlybuyer(uint256 item_id) {
        require(
            msg.sender == Items[item_id].ItemBuyer,
            "only buyer can call this function"
        );
        _;
    }
    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Address is blacklisted");
        _;
    }
    modifier onlyBeforeDeadline(uint256 itemId) {
        require(
            block.timestamp <= Items[itemId].deadline,
            "confirmation deadline has passed"
        );
        _;
    }
    modifier isConfirmationDeadlinePassed(uint256 itemId) {
        // return block.timestamp > Items[itemId].deadline;
        require(
            block.timestamp > Items[itemId].deadline,
            "Confirmation deadline has not passed yet"
        );
        Items[itemId].status == ItemStatus.Completed;
        _;
    }
    modifier IsConfirmed(uint256 itemid) {
        require(block.timestamp > Items[itemid].deadline);
        Items[itemid].isconfirmed = true;
        GetItemsDetails[itemid].isconfirmed = true;
        _;
    }

    struct ItemsList {
        bytes ItemName;
        string ItemDiscription;
        uint256 ItemPrice;
        address payable ItemSeller;
        address payable ItemBuyer;
        uint256 deadline;
        ItemStatus status;
        bool ItemExist;
        bool hasExist;
        bool isconfirmed;
        uint256 PeriodOfTime;
    }
    uint256 private ItemId;
    mapping(uint256 => ItemsList) public Items;
    ItemsList[] private GetItemsDetails;
    mapping(uint256 => uint256) public orderAmounts;
    mapping(address => uint256) public Transferbalances;
    mapping(address => bool) private blacklist;

    function ListItems(
        bytes memory _ItemName,
        string memory _ItemDiscription,
        uint256 _ItemPrice
    ) external notBlacklisted {
        ItemsList storage items = Items[ItemId];
        require(!Items[ItemId].hasExist, "Already Exist");
        require(_ItemPrice > 0, "item price must be greater then 0");

        Items[ItemId].hasExist = true;
        items.ItemName = _ItemName;
        items.ItemDiscription = _ItemDiscription;
        items.ItemPrice = _ItemPrice * 1e18;
        items.ItemSeller = payable(msg.sender);
        items.ItemBuyer = payable(address(0));
        items.status = ItemStatus.Available;
        items.ItemExist = true;
        items.PeriodOfTime = 5 minutes;
        GetItemsDetails.push(items);
        ItemId++;
        emit Available(
            ItemId,
            _ItemName,
            _ItemDiscription,
            _ItemPrice,
            msg.sender,
            ItemStatus.Available
        );
    }

    function CancelFromList(uint256 _item_id)
        public
        itemExists(_item_id)
        onlyseller(_item_id)
    {
        require(Items[_item_id].status == ItemStatus.Available,"sold item can't cancel");
        Items[_item_id].status = ItemStatus.Cancelled;
        emit Cancelled(_item_id, msg.sender, ItemStatus.Cancelled);
    }

    function Purchase(uint256 Item_id)
        external
        payable
        itemExists(Item_id)
        notBlacklisted
    {
        require(msg.sender.balance > 0, "Insufficient Balance");
        require(
            Items[Item_id].status == ItemStatus.Available,
            "Item stuts must be available"
        );
        require(
            msg.value == Items[Item_id].ItemPrice,
            "amount must be equal to price"
        );
        require(
            msg.sender != Items[Item_id].ItemSeller,
            "Seller cannot buy their own item"
        );

        Items[Item_id].deadline = block.timestamp + Items[Item_id].PeriodOfTime;
        Items[Item_id].ItemBuyer = payable(msg.sender);
        Items[Item_id].isconfirmed = false;
        GetItemsDetails[Item_id].ItemBuyer = payable(msg.sender);
        GetItemsDetails[Item_id].isconfirmed = true;
        Transferbalances[msg.sender] += msg.value;
        orderAmounts[Item_id] += msg.value;

        Items[Item_id].status = ItemStatus.Sold;
        GetItemsDetails[Item_id].status = ItemStatus.Sold;

        emit Sold(Item_id, msg.value, msg.sender, ItemStatus.Sold);
    }

    function Confirmation(uint256 Item_id)
        public
        itemExists(Item_id)
        onlybuyer(Item_id)
        notBlacklisted
        onlyBeforeDeadline(Item_id)
    {
        require(Items[Item_id].status == ItemStatus.Sold, "Item must b sold");
       
        Items[Item_id].status = ItemStatus.Confirmed;
        GetItemsDetails[Item_id].status = ItemStatus.Confirmed;

        Items[Item_id].isconfirmed = true;


        emit Confirmpurchase(msg.sender, ItemStatus.Completed);
    }

    function DisputeTransaction(uint256 Item_id)
        public
        itemExists(Item_id)
        onlybuyer(Item_id)
        notBlacklisted
        onlyBeforeDeadline(Item_id)
    {
        require(
            Items[Item_id].status == ItemStatus.Sold,
            "Cannot dispute an unsold item"
        );
        require(address(this).balance > 0, "No funds available for transfer");
        Items[Item_id].status = ItemStatus.Disputed;

        emit Disputed(msg.sender, ItemStatus.Disputed);
    }

    function SellerWithdraw(uint256 Item_id)
        public
        itemExists(Item_id)
        onlyseller(Item_id)
        isConfirmationDeadlinePassed(Item_id)
        IsConfirmed(Item_id)
    {
        uint256 amount = orderAmounts[Item_id];
        
       
        require(amount > 0, "No balance to withdraw");
         require(Items[Item_id].status == ItemStatus.Sold,"Itemstatus must be sold");
        require(Items[Item_id].status != ItemStatus.Disputed,"Itemstatus not be disputed" );
        require(Items[Item_id].status != ItemStatus.Cancelled,"Itemstatus not be canceled");

        orderAmounts[Item_id] = 0;

      Transferbalances[msg.sender] = 0;
        Items[Item_id].status = ItemStatus.Completed;
        GetItemsDetails[Item_id].status = ItemStatus.Completed;
        payable(Items[Item_id].ItemSeller).transfer(amount);

        emit sellerWithdraw(ItemId, ItemStatus.Completed, amount, msg.sender);
    }

    function ResolveDispute(uint256 Item_Id)
        public
        itemExists(Item_Id)
        onlyAdmin
        isConfirmationDeadlinePassed(Item_Id)
    {
        require(address(this).balance > 0, "No funds available for withdrawal");
        require(
            Items[Item_Id].status == ItemStatus.Disputed,
            "Item Status are nor disputed"
        );
        uint256 amount = orderAmounts[Item_Id];
        require(amount > 0, "No balance to withdraw");
        orderAmounts[Item_Id] = 0;
       Transferbalances[msg.sender] = 0;
        if (Items[Item_Id].isconfirmed == false) {
            payable(Items[Item_Id].ItemBuyer).transfer(amount);
        } else {
            payable(Items[Item_Id].ItemSeller).transfer(amount);
        }
        Items[Item_Id].status == ItemStatus.ResolveDisputed;
        Items[Item_Id].status = ItemStatus.ResolveDisputed;
        GetItemsDetails[Item_Id].status = ItemStatus.ResolveDisputed;
        emit resolveDispute(Item_Id, Items[Item_Id].status, amount, msg.sender);
    }
    function Beforedeadlinewithdraw(uint _Itemid) public itemExists(_Itemid) onlyAdmin {
     require(Items[_Itemid].status == ItemStatus.Confirmed , "Item must be confirmed");
     require(block.timestamp <= Items[_Itemid].deadline,"Confirmation deadline meet");
     uint256 amount = orderAmounts[_Itemid];
        require(amount > 0, "No balance to withdraw");

        orderAmounts[_Itemid] = 0;

      Transferbalances[msg.sender] = 0;
        Items[_Itemid].status = ItemStatus.Completed;
        GetItemsDetails[_Itemid].status = ItemStatus.Completed;
        payable(Items[_Itemid].ItemSeller).transfer(amount);

        emit sellerWithdraw(_Itemid, ItemStatus.Completed, amount, msg.sender);

    }

    function addToBlacklist(address _address) external onlyAdmin {
        require(_address != Admin,"you can't blacklist admin");
        blacklist[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyAdmin {
        blacklist[_address] = false;
    }

    function getitemDetails()
        public
        view
        returns (ItemsList[] memory Itemdetails)
    {
        uint256 length = GetItemsDetails.length;
        Itemdetails = new ItemsList[](length);
        for (uint256 i = 0; i < length; i++) {
            Itemdetails[i] = GetItemsDetails[i];
        }

        return Itemdetails;
    }

    function gettotalitems() public view returns (uint256) {
        return GetItemsDetails.length;
    }
    
}
