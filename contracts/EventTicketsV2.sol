pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    //Ryan added
    address public owner = msg.sender;
        /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    uint   PRICE_TICKET = 100 wei;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    //Ryan added 
    struct Event {
        string description;
        string URL;
        uint totalTickets;
        uint sales;
        mapping(address => uint) buyerTickets; 
        address[] buyer;
        bool isOpen;
    }
    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    //Ryan added
    mapping(uint => Event) public events;
    
    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    //Ryan added...
    modifier verifyOwner(address _address){require(msg.sender == _address); _;}
    
    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _URL, uint _numTickets)
        verifyOwner(owner)
        public
        returns(uint)
    {
        events[idGenerator] = Event({description: _description, URL: _URL, totalTickets: _numTickets, sales: 0, buyer: new address[](0), isOpen: true});
        emit LogEventAdded(_description, _URL, _numTickets, idGenerator);
        idGenerator += 1;
        return idGenerator;
    }
    
    

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventId)
      public
      view
      returns (string memory description, string memory URL, uint availableTickets, uint sales, bool isOpen)
    {
        description = events[_eventId].description;
        URL = events[_eventId].URL;
        availableTickets = events[_eventId].totalTickets - events[_eventId].sales;
        sales = events[_eventId].sales;
        isOpen = events[_eventId].isOpen;
        return (description, URL, availableTickets, sales, isOpen);
    }
    
    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventId, uint _numTickets)
        public
        payable
        returns (bool)
    {
        require(events[_eventId].isOpen == true && msg.value >= (_numTickets * PRICE_TICKET) && (events[_eventId].totalTickets - events[_eventId].sales) >= _numTickets, "Error");
        
        events[_eventId].buyer.push(msg.sender);
        events[_eventId].buyerTickets[msg.sender] = _numTickets;
        events[_eventId].sales += _numTickets;
        
        if(msg.value > (_numTickets * PRICE_TICKET)){
            msg.sender.transfer(msg.value - (_numTickets * PRICE_TICKET));
        }
        
        emit LogBuyTickets(msg.sender, _eventId, _numTickets);
    
        return true;
    }
    
    
    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId)
        public
        returns (bool)
    {
        uint buyer_ticket = events[_eventId].buyerTickets[msg.sender];
        require(buyer_ticket > 0,"No tickets purchased");
        events[_eventId].sales -= buyer_ticket;
        msg.sender.transfer(PRICE_TICKET * buyer_ticket);
        emit LogGetRefund(msg.sender, _eventId, buyer_ticket);
        return true;
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventId)
        public
        view
        returns(uint)
    {
        return events[_eventId].buyerTickets[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventId)
        public
        verifyOwner(owner)
    {
        events[_eventId].isOpen = false;
        uint balance = events[_eventId].sales * PRICE_TICKET;
        msg.sender.transfer(balance);
        emit LogEndSale(msg.sender, balance, _eventId);
    }
}