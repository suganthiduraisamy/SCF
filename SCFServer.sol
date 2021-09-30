// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

// CONTRACT FOR CUSTOMER RELATED OPERATIONS
contract SCFCustomerOperations {
    // BookingStatus of customer
    enum SCFBookingStatus  {INITIATED, CONFIRMED, AIRLINE_CANCELLED_REFUND_COMPLETED, USER_CANCELLED_REFUND_COMPLETED, CLAIM_REFUND_COMPLETED, DELAY, COMPLETED}
    uint8 SCFPredefinedRefundPercentage = 70;
    
    // Data structure for booking data
    struct SCFBookingData {
        address payable customer; // Address of the customer
	    string flight_number;
		uint256 travel_timestamp; // Travel timestamp 
		uint256 booking_timestamp;    // Timestamp when  booking happened
		uint256 delay;
		uint8 seat_category;
		SCFBookingStatus booking_status; // current status of the booking
		uint256 booking_amount; // booking cost
		string booking_comment; // Comment specifying the current status of the booking
		uint booking_id; 
		uint8 penalty_percentage; // penalty percentage calculated based on cancellation time
    }
    SCFBookingData _bookingData;
    
    // Invoked when Customer initiates the booking process
    constructor(address payable _customer, string memory _flight_number, uint8 _seat_category, uint256 _travel_timestamp) {
		_bookingData = SCFBookingData({
									customer : _customer,
									flight_number : _flight_number,
									seat_category : _seat_category,
									travel_timestamp: _travel_timestamp,
									booking_timestamp: block.timestamp,
									booking_status : SCFBookingStatus.INITIATED,
									booking_amount: 0,
									booking_comment: '',
									booking_id : 0,
									delay: 0,
									penalty_percentage: 10
									});				
							
    }
    function updateDelay(uint256 delay) public{
        _bookingData.delay = delay;
    }
    function claimRefund(uint8 _flightStatus, uint _flightStatusUpdateTime) public  returns (uint8) {
        uint256 currentTime= block.timestamp;
        
        //refund can be made only after 24h from scheduled departure time
        if (currentTime < (_bookingData.travel_timestamp + 86400)) {
           return 0;
        }
        // They should get a complete refund in case of cancellation by the airline. 
        // This is taken care of in airline update status if the flight is cancelled
        // refund cannot be made for booking if the booking is in these states
        if (_bookingData.booking_status == SCFBookingStatus.USER_CANCELLED_REFUND_COMPLETED &&
            _bookingData.booking_status == SCFBookingStatus.CLAIM_REFUND_COMPLETED &&
            _bookingData.booking_status == SCFBookingStatus.AIRLINE_CANCELLED_REFUND_COMPLETED &&
            _bookingData.booking_status == SCFBookingStatus.COMPLETED) {
                return 0;
        }
        
        uint8 refundPercent;
        // If flight not updated the status after 24 hours of flight departure
        if (_flightStatus == uint8(SCFAirlineOperations.SCFFlightStatus.UNKNOWN)  && _flightStatusUpdateTime == 0) {
            refundPercent = 100;
            _bookingData.booking_status = SCFBookingStatus.AIRLINE_CANCELLED_REFUND_COMPLETED;
            _bookingData.booking_comment = "NO_UPD";
        }
        // If flight status is DELAY, refund the predefined refund percentage
        if (_flightStatus == uint8(SCFAirlineOperations.SCFFlightStatus.incident) || 
        _flightStatus == uint8(SCFAirlineOperations.SCFFlightStatus.diverted)) {
            refundPercent =  SCFPredefinedRefundPercentage;
            _bookingData.booking_status = SCFBookingStatus.CLAIM_REFUND_COMPLETED;
            _bookingData.booking_comment = "DELAY";
        }
        return refundPercent;
}
// This function will be invoked when the customer performs the cancel booking. 
    // this will return  penalty percentage as defined by the airlines
    function calculatePenaltyPercentage(uint _travel_timestamp) public returns (uint8) {
        uint256 current_timestamp = block.timestamp;
        uint256 time_diff = _travel_timestamp + _bookingData.delay- current_timestamp;

        if(time_diff < 7200){// less than 2 hours before departure
            _bookingData.penalty_percentage = 0;
        } else if(time_diff >= 7200 && time_diff < 18000){// 2-5 hours before departure
            _bookingData.penalty_percentage = 50;
        } else if(time_diff >=18000 && time_diff < 36000){// 5-10 hours before departure
            _bookingData.penalty_percentage = 40;
        } else if(time_diff >=36000 && time_diff < 54000){// 10-15 hours before departure
            _bookingData.penalty_percentage = 20;
        } 
        else { 
            _bookingData.penalty_percentage = 10;
        }
        return _bookingData.penalty_percentage;
    }
 
    // Set function: Invoked when booking status of customer to be updated.
    function updateBookingStatus(SCFBookingStatus _booking_status) public returns (bool) {
        _bookingData.booking_status = _booking_status;
        
        if (_booking_status == SCFBookingStatus.CONFIRMED)
            _bookingData.booking_comment = "CNF";
            
        if (_booking_status == SCFBookingStatus.AIRLINE_CANCELLED_REFUND_COMPLETED)
            _bookingData.booking_comment = "FLI CAN";
            
        if (_booking_status == SCFBookingStatus.USER_CANCELLED_REFUND_COMPLETED)
            _bookingData.booking_comment = "CUS CAN";
            
        if (_booking_status == SCFBookingStatus.CLAIM_REFUND_COMPLETED)
            _bookingData.booking_comment = "REFUNDED";   
        
        if (_booking_status == SCFBookingStatus.DELAY)
            _bookingData.booking_comment = "DELAYED";   
        
            
        return true;    
       
    }
    
    // Set function: Invoked when customer finished with the booking process to update the unique booking id and actual booking amount
    function updateBookingDetails(uint _booking_id, uint _booking_amount) public returns (bool) {
        _bookingData.booking_id = _booking_id;
        _bookingData.booking_amount = _booking_amount;
        
         return true;
    }
    
    // Get function: To get the customer address of booking
    function getBookingCustomerAddress() public view returns(address payable) {
        return (_bookingData.customer);
    }
    
    // Get function: To get the booking amount of booking
    function getBookingAmount() public view returns(uint256) {
        return (_bookingData.booking_amount);
    }
   
    // Reset function: Invoked when the booking gets cancelled
    function resetBookingData() public returns (bool) {
        _bookingData.booking_amount = 0;
        _bookingData.booking_id = 0;
        _bookingData.flight_number = '';
        _bookingData.seat_category = 0;
        
        return true;
    }

    //Returns customer address, booking amount, seat category, booking status, booking comment
    function getBookingData() public view returns (address payable, uint, uint8, uint8, string memory) {
        return (_bookingData.customer, _bookingData.booking_amount, uint8(_bookingData.seat_category), 
        uint8(_bookingData.booking_status), _bookingData.booking_comment);
    }
    
    function getTravelTimestamp() public view returns (uint) {
        return (_bookingData.travel_timestamp);
    }
    
}

// CONTRACT FOR AIRLINE RELATED OPERATIONS
contract SCFAirlineOperations {
    
    // User defined variables
    enum SCFFlightStatus {UNKNOWN, scheduled, active, landed, cancelled, incident, diverted}
    enum SCFSeatCategory {UNKNOWN, Economy, PremiumEconomy, BusinessClass, FirstClass}
    
    // Data structure to hold the flight data and booking details of the flight
    struct SCFFlightData {
        address airline; 
        string flight_number;
        uint256 flight_datetime; //Flight departure time
        uint256 flight_status_updatetime;  //Time at which airline update the flight status
        SCFFlightStatus flight_status;
        string flight_status_comment; 
        uint32 number_of_seats;
        uint256 delay;
        uint8 booking_count;  //counter for number of booking
        uint256[] booking_ids; // Array of booking ids per flight. 
    }
    SCFFlightData _flightData;
    uint8 bookingIndex = 0;
    mapping(SCFSeatCategory => uint) _seatPriceList; // Key is seat caetgory and value is the price in ethers
    
    // Invoked during flight data intialization
    constructor(address _airline, string memory _flightNo, uint256 _flight_timestamp, uint32 _number_of_seats) {
        _flightData = SCFFlightData({
                                    airline: _airline,
                                    flight_number: _flightNo,
                                    flight_datetime: _flight_timestamp, 
                                    flight_status: SCFFlightStatus.UNKNOWN,
                                    flight_status_updatetime: 0,
                                    booking_count: 0,
                                    number_of_seats: _number_of_seats,
                                    booking_ids: new uint[](_number_of_seats),
                                    flight_status_comment: '',
                                    delay: 0
                                });
    }
    
    function updateDelay(uint256 delay) public {
        _flightData.delay=delay;
    }
    
    function updateComment(string memory comment) public returns(string memory){
        _flightData.flight_status_comment = comment;
        return _flightData.flight_status_comment;
    }
    
    function getComment() public view returns(string memory){
        return _flightData.flight_status_comment;
    }
    //Set function: Invoked when customer is booking. Update the booking id in the list
    function addToBookingList(uint _bookingId) public returns (bool) {
        _flightData.booking_ids[bookingIndex] = _bookingId;
        _flightData.booking_count = _flightData.booking_count + 1;
        bookingIndex = _flightData.booking_count;
        
        return true;
    }
    
    //Set function: Invoked when customer is cancelling the booking. Delete the booking id from the list
    function deleteFromBookingList(uint _bookingId) public returns (bool) {
        for (uint8 i = 0; i < _flightData.booking_ids.length; i++) {
            if (_flightData.booking_ids[i] == _bookingId) {
                _flightData.booking_ids[i] = 0;
                bookingIndex = i;
                 _flightData.booking_count = _flightData.booking_count - 1;
            }
        }
        
        return true;
    }

    // Set function: Invoked when airline upates the actual flight status                            
    function updateFlightStatus(uint8 _flightStatus) public returns (bool) {
        _flightData.flight_status_updatetime = block.timestamp;
        _flightData.flight_status = SCFFlightStatus(_flightStatus);
        
        if (_flightStatus == uint8(SCFFlightStatus.scheduled))
            _flightData.flight_status_comment = "ON_TIME";
            
        if (_flightStatus == uint8(SCFFlightStatus.cancelled))
            _flightData.flight_status_comment = "AIR_CAN";
            
        if (_flightStatus == uint8(SCFFlightStatus.incident) || _flightStatus == uint8(SCFFlightStatus.diverted))
            _flightData.flight_status_comment = "FLI_DEL"; 
            
         if (_flightStatus == uint8(SCFFlightStatus.landed))
            _flightData.flight_status_comment = "FLI_DONE";        
       
        return true;
    }  
    
    // Update function: Sets the seat price for the category
    function updateFlightSeatPrice(uint8 _seatCategory, uint _seatPrice) public returns (bool) {
        _seatPriceList[SCFSeatCategory(_seatCategory)] = _seatPrice;
        
        return true;    
    }
    
    // Reset function: Invoked during cancellation of flight
    function resetFlightBookingData() public returns (bool) {
        _flightData.booking_count = 0;
        bookingIndex = 0;
        delete _flightData.booking_ids;
        
        return true;
    }
    
    // Validity function: Returns true if it finds the given booking_id, false otherwise
    function validFlightBookingId(uint _bookingId) public view returns (bool) {
        for (uint8 i = 0; i < _flightData.booking_ids.length; i++) {
            if (_flightData.booking_ids[i] == _bookingId) {
                return true;
            }
        }
        return false;
    }
    
    // Get function: Gets the seat price for the category
    function getSeatPrice(uint8 _seatCategory) public view returns (uint) {
        return (_seatPriceList[SCFSeatCategory(_seatCategory)]);    
    }
    
    // Get function: To get the array of booking ids of flight
    function getBookingIds() public view returns (uint[] memory, uint) {
        return (_flightData.booking_ids, _flightData.booking_ids.length);
    }
    
    // Get function: To get the total booking count 
    function getBookingCount() public view returns (uint8) {
        return _flightData.booking_count;
    }
    
    // Get function: Returns booking_ids list and booking count.
    function getFlightBookingData() public view returns(uint[] memory, uint8) {
        return (_flightData.booking_ids, _flightData.booking_count);
    }
    
    // Get function: Returns flight status and comment
    function getFlightStatus() public view returns(uint8, string memory) {
        return (uint8(_flightData.flight_status), _flightData.flight_status_comment);
    }
    
    // Get function: Returns flight status update time
    function getFlightStatusUpdateTime() public view returns(uint) {
        return (_flightData.flight_status_updatetime);
    }
    
    // Get function: Returns flight timestamp
    function getFlightTime() public view returns(uint) {
        return (_flightData.flight_datetime);
    }
}

// MAIN CONTRACT OF ENTRY
contract SCFServer {
    //Utilities utils = new Utilities();
    //DateTime dateUtils = new DateTime();
    address private SCFCreator;   // Airline address
    address private SCFCurrentBookingOwner;  // Current booking customer's address
    uint seed = 0;   //For random id generation
    
    // To store the current booking details, needed for "getCurrentBookingData" function
    uint private current_booking_id;
    string private current_flight_number;
    uint private current_flight_travel_date;
    uint8 private seat_category;
    string private current_booking_comment;
  
    // Mapping for each AirlineOperations instance with the first key being the flight number and internal key is flight_start_timestamp
    mapping(string => mapping(uint => SCFAirlineOperations)) _flightList;
   
    // As we are deploying the contract for each airline, first key is flightNo, internal key is booking id and the value will be booking data of customer
    mapping(string => mapping(uint => SCFCustomerOperations)) _bookingList;
  
    // Main entry: Simulate flight data and objects for easy testing
    constructor() {
        SCFCreator = msg.sender;
        
        // Simulated flight data
        // https://www.epochconverter.com/ :  Local time: 2021/9/25 9:30 AM
        uint flight_start_timestamp = 1632500195;
        
        SCFAirlineOperations flight1 = new SCFAirlineOperations(SCFCreator, "F721", flight_start_timestamp, 10);
        _flightList["F721"][flight_start_timestamp] = flight1;
        
        flight1.updateFlightSeatPrice(1, 1 ether);
        flight1.updateFlightSeatPrice(2, 5 ether);
        flight1.updateFlightSeatPrice(3, 10 ether);
        flight1.updateFlightSeatPrice(4, 15 ether);
 
        // https://www.epochconverter.com/ :  Local time: 2021/9/25 10:30 AM
        flight_start_timestamp = 1632362836;
        SCFAirlineOperations flight2 = new SCFAirlineOperations(SCFCreator, "F755", flight_start_timestamp, 20);
        _flightList["F755"][flight_start_timestamp] = flight2;
        
        flight2.updateFlightSeatPrice(1, 1 ether);
        flight2.updateFlightSeatPrice(2, 5 ether);
        flight2.updateFlightSeatPrice(3, 10 ether);
        flight2.updateFlightSeatPrice(4, 15 ether);
    }
    
    modifier onlyCreator() {
        require(msg.sender == SCFCreator, "Only Airline can do this action");
        _;
    }
    
    // Fallback function: to receive ethers in contract
    receive() external payable {
        
    }
    
    function getFlightComment(string memory _flight_number, uint256 _flight_start_timestamp) public view returns(string memory){
         SCFAirlineOperations flight = _flightList[_flight_number][_flight_start_timestamp];
         return(flight.getComment());
    }
    
    // Airline function: To feed in flight data
    function updateFlightData(string memory _flight_number, uint256 _flight_start_timestamp, uint32 _number_of_seats) public onlyCreator {
        SCFAirlineOperations flight = new SCFAirlineOperations(msg.sender, _flight_number, _flight_start_timestamp, _number_of_seats);
        _flightList[_flight_number][_flight_start_timestamp] = flight;
        
        flight.updateFlightSeatPrice(1, 1 ether);
        flight.updateFlightSeatPrice(2, 5 ether);
        flight.updateFlightSeatPrice(3, 10 ether);
        flight.updateFlightSeatPrice(4, 15 ether);
    }
    
    // Airline function: To update the flight seat price
    function updateFlightSeatPrice(string memory _flight_number, uint256 _flight_start_timestamp, uint8 _seat_category, uint _price) public onlyCreator {
        SCFAirlineOperations flight = _flightList[_flight_number][_flight_start_timestamp];
        flight.updateFlightSeatPrice(_seat_category, _price * 1 ether);
    }
    
    //Oracle CRON Job injects data in this method 
    function handleFlightStatus(string memory _flightNumber, string memory _flightStatus, uint256 _departureTime, uint256 _actualTime) public returns(string memory) {
        SCFAirlineOperations flight = _flightList[_flightNumber][_departureTime];
        updateFlightStatus(_flightNumber, _departureTime, getFlightStatusIndex(_flightStatus), _actualTime - _departureTime);
        flight.updateComment("UPDATED");
        return flight.getComment();
    }
    
    // Airline operation: To update the flight status: scheduled,incident, , cancelled, diverted
    // the cases of diverted and incident are treated as delay scenarios
    // To be done: Flight status can be updated once. In that case, at the end of this function, update flight status as COMPLETED
    // Initially, check if the status is COMPLETED, if so, stop proceeding further.
    function updateFlightStatus(string memory _flight_number, uint _flight_start_timestamp, uint8 _flightStatus,uint delay) public onlyCreator returns (bool){
        uint[] memory bookingIds;
        uint bookedAmount;
        uint length;
        address payable bookedCustomer;
        
        SCFAirlineOperations flight = _flightList[_flight_number][_flight_start_timestamp];
        (uint8 flightStatus,) = flight.getFlightStatus();
        require(flightStatus != uint8(SCFAirlineOperations.SCFFlightStatus.landed), "COMPLETED"); 
        
        flight.updateFlightStatus(_flightStatus);
        (bookingIds, length) = flight.getBookingIds();
        for (uint8 i = 0; i < length; i++) {
             if (bookingIds[i] != 0) { // Only process for valid booking ids.
                SCFCustomerOperations booking = _bookingList[_flight_number][bookingIds[i]];
                // In case of CANCEL, refund the amount to all booked customers of the flight
                if (_flightStatus == uint8(SCFAirlineOperations.SCFFlightStatus.cancelled)) {
                   bookedAmount = booking.getBookingAmount();
                    require(getContractBalance() >= bookedAmount, "Insufficient funds");
                
                    //Refund the full booking amount to customer
                    bookedCustomer = booking.getBookingCustomerAddress();
                    bookedCustomer.transfer(bookedAmount);
                
                    //update the corresponding customer booking status and reset the booking data
                    booking.updateBookingStatus(SCFCustomerOperations.SCFBookingStatus.AIRLINE_CANCELLED_REFUND_COMPLETED);
                    booking.resetBookingData();
                
                    // Reset the flight booking data also
                    flight.resetFlightBookingData();
                    // Allowing the airline to update the flight status to only once. 
                    flight.updateFlightStatus(uint8(SCFAirlineOperations.SCFFlightStatus.landed));
                }
                // In case of ONTIME, transfer the booking amount to the airline address
                if (_flightStatus == uint8(SCFAirlineOperations.SCFFlightStatus.scheduled)) {
                    bookedAmount = booking.getBookingAmount();
                    require(getContractBalance() >= bookedAmount, "Insufficient funds");
                
                    //Transfer the booking amount to airline and update the booking status to COMPLETED
                    payable(msg.sender).transfer(bookedAmount);
                    booking.updateBookingStatus(SCFCustomerOperations.SCFBookingStatus.COMPLETED);
            
                    // Reset the flight booking data also
                    flight.resetFlightBookingData();
                    // Allowing the airline to update the flight status to only once. 
                    flight.updateFlightStatus(uint8(SCFAirlineOperations.SCFFlightStatus.landed));
                }
                //in case of delay
                if (_flightStatus == uint8(SCFAirlineOperations.SCFFlightStatus.incident) || _flightStatus == uint8(SCFAirlineOperations.SCFFlightStatus.diverted)){
                    flight.updateDelay(delay);
                    booking.updateDelay(delay);
                    flight.updateFlightStatus(_flightStatus);
                    booking.updateBookingStatus(SCFCustomerOperations.SCFBookingStatus.DELAY);
                }
             }
        }
        return true;
    }
    
    // Utility function: Booking id generation
    function randomID() private returns (uint) {
        seed++;  
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) %100;
    }

// we get the flight status as string from the oracle so we need to convert it back to uint index of our enum
// to preserve functionality, there could be a better way to do this, but right now falling back to brute logic of string comparison
    function getFlightStatusIndex(string memory stringStatus) private pure returns(uint8) {
        uint8 index = 0;// UNKNOWN
        
        if(compareStrings(stringStatus, 'scheduled'))
            index = 1;
        else if(compareStrings(stringStatus, 'active'))
            index =  2;
        else if(compareStrings(stringStatus, 'landed'))
            index =  3;
        else if(compareStrings(stringStatus, 'cancelled'))
            index =  4;
        else if(compareStrings(stringStatus, 'incident'))
            index =  5;
        else if(compareStrings(stringStatus, 'diverted'))
            index =  6;
        return index;
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    // Customer function: To book a ticket
    function initiateBooking(string memory _flight_number, uint8 _seat_category, uint256 _travel_timestamp) public payable returns (bool) {
        //Validation of input to be added
        
        uint256 booking_amount;
        
        // Ensure booking is done from customer account
        require(msg.sender != SCFCreator, "OWNER");
        
        // Ensure booking is done only for the future datetime
        require(_travel_timestamp > block.timestamp, "DT MISS");
        
        // Ensure booking is not done on completed flight
        SCFAirlineOperations flight = _flightList[_flight_number][_travel_timestamp];
        (uint8 flight_status,) = flight.getFlightStatus();
        require(flight_status != 4, "FLI DONE");
        
        SCFCustomerOperations booking = new SCFCustomerOperations(payable(msg.sender), _flight_number, _seat_category, _travel_timestamp);
        
        //Send the booking amount to the contract address
        booking_amount = flight.getSeatPrice(_seat_category);
        
        require(msg.value == booking_amount, "FUND");
        payable(address(this)).transfer(msg.value);
        
        current_booking_id = randomID();
        _bookingList[_flight_number][current_booking_id] = booking;
        
        current_flight_number = _flight_number;
        current_flight_travel_date = _travel_timestamp;
        seat_category = _seat_category;
        
        flight.addToBookingList(current_booking_id);
        booking.updateBookingStatus(SCFCustomerOperations.SCFBookingStatus.CONFIRMED);
        booking.updateBookingDetails(current_booking_id, booking_amount);
        
        current_booking_comment = "CNF";
        SCFCurrentBookingOwner = msg.sender;
        return true;
    }
    
    // Customer function: To cancel a indivdual booking
    function cancelBooking(string memory _flight_number, uint _flight_start_timestamp, uint32 _booking_id) public returns (bool) {
        uint8 penalty_percentage;
        
        SCFAirlineOperations flight = _flightList[_flight_number][_flight_start_timestamp];
        // Validate: Check if the booking_id is valid.
        require(flight.validFlightBookingId(_booking_id) == true, "INVALID BOOKING_ID");
        
        SCFCustomerOperations booking = _bookingList[_flight_number][_booking_id];
        require(payable(msg.sender) == booking.getBookingCustomerAddress(), "OWN");
        
        // Get the penalty_percentage as defined by the airlines in the contract. Allow cancel only till 2 hours of flight departure
        penalty_percentage = booking.calculatePenaltyPercentage(_flight_start_timestamp);
        require(penalty_percentage != 0, "Cancellation allowed only till 2 hours before flight departure");
     
        // penalty amount to be payed to the airline
        // rest of the amount to be payed back to the customer
        uint256 amount = booking.getBookingAmount();
        uint256 penalty = amount * penalty_percentage / 100;

        require(getContractBalance() >= (amount - penalty), "Insufficient funds in contract");
        payable(msg.sender).transfer(amount - penalty);
        
        require(getContractBalance() >= penalty, "Insufficient funds in contract");
        payable(SCFCreator).transfer(penalty);
        
        booking.updateBookingStatus(SCFCustomerOperations.SCFBookingStatus.USER_CANCELLED_REFUND_COMPLETED);
        booking.resetBookingData();
        flight.deleteFromBookingList(_booking_id);
        
        return true;
    }
    
    // Customer function: To claim refund
    function claimRefund(string memory _flight_number, uint _flight_start_timestamp, uint _booking_id) public returns (bool) {
        SCFAirlineOperations flight = _flightList[_flight_number][_flight_start_timestamp];
          // Validate: Check if the booking_id is valid.
        require(flight.validFlightBookingId(_booking_id) == true, "INVALID BOOKING_ID");
        
        SCFCustomerOperations booking = _bookingList[_flight_number][_booking_id];
        require(payable(msg.sender) == booking.getBookingCustomerAddress(), "OWN");
      
        (uint8 flightStatus,) = flight.getFlightStatus();
        uint8 refundPercentage = booking.claimRefund(flightStatus, flight.getFlightStatusUpdateTime());
        
        if (refundPercentage == 0) {
            return false;
        } else {
            uint256 amount = booking.getBookingAmount();
            uint256 refund = amount * refundPercentage / 100;

            require(getContractBalance() >= refund, "Insufficient funds in contract");
            payable(msg.sender).transfer(refund);
            
            require(getContractBalance() >= (amount - refund), "Insufficient funds in contract");
            payable(SCFCreator).transfer(amount - refund);

            return true;
        }
    }
    
    // To be decided who can be the owner of this function
    function getContractBalance() public view returns (uint256) {
        address payable contractAddress = payable(address(this));
        return (contractAddress.balance);
    }

    // Customer Function: to get the booking id and flight details immediately after booking
    // Returns booking_id, flight_number, travel date, seat_category, booking_comment
    function getCurrentBookingData() public view returns (uint, string memory, uint, uint8, string memory) {
        require(payable(msg.sender) == SCFCurrentBookingOwner, "OWN");
        return (current_booking_id, current_flight_number, current_flight_travel_date, seat_category, current_booking_comment);
    }
    
     // To be decided who can be the owner of this function
    function getBookingData(string memory _flight_number, uint _booking_id) public view returns(address payable, uint, uint8, uint8, string memory) {
        SCFCustomerOperations booking = _bookingList[_flight_number][_booking_id];
        return booking.getBookingData();
    }
    
    // Airline function: To get the booking details for a flight. 
    // To be added onlyCreator modifier later, made it easy for unit testing
    function getFlightBookingData(string memory _flight_number, uint _flight_start_timestamp) public view returns(uint[] memory, uint8) {
        SCFAirlineOperations flight = _flightList[_flight_number][_flight_start_timestamp];
        return flight.getFlightBookingData();
    }
    
    
    // the time format conversion from string YYYY-MM-DDTHH:mm:SS+00:00 to epoch is too costly operation 
    //so commenting out all utils methods and formatting date received from Oracle to epoch timestamp 
    
    // function getTimeStampz(string memory _departureTime) public view returns (uint256)
    // {
    //  //bool result = false;
    //  //Thursday, September 23, 2021 5:09:26 PM
    //  //sample time from oracle response - 2021-09-22T23:59:00+00:00
    //  string[] memory dateparts = utils.split(_departureTime, "T");
    //  string[] memory timeparts = utils.split(dateparts[1],"+");
    //  timeparts = utils.split(timeparts[0],":");
    //  dateparts = utils.split(dateparts[0], "-");
    //  return dateUtils.toTimestamp(uint16(utils.stringToUint(dateparts[0])) , uint8(utils.stringToUint(dateparts[1])), 
    //  uint8(utils.stringToUint(dateparts[2])), uint8(utils.stringToUint(timeparts[0])), 
    //  uint8(utils.stringToUint(timeparts[1])), uint8(utils.stringToUint(timeparts[2])));
    // }
    
}

//contract Utilities{
    
//     function stringToUint(string memory s) public pure returns (uint) {
//     bytes memory b = bytes(s);
//     uint result = 0;
//     uint oldResult = 0;
//     for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
//         if (b[i] >= bytes1(uint8(48)) && b[i] <= bytes1(uint8(57))) {
//             // store old value so we can check for overflows
//             oldResult = result;
//             result = result * 10 + (uint8(b[i]) - 48); // bytes and int are not compatible with the operator -.
            
//         } 
//     }
//     return result; 
// }
 
    // function split(string memory _base, string memory _value)
    //     public
    //     pure
    //     returns (string[] memory splitArr) {
    //     bytes memory _baseBytes = bytes(_base);

    //     uint _offset = 0;
    //     uint _splitsCount = 1;
    //     while (_offset < _baseBytes.length - 1) {
    //         int _limit = _indexOf(_base, _value, _offset);
    //         if (_limit == -1)
    //             break;
    //         else {
    //             _splitsCount++;
    //             _offset = uint(_limit) + 1;
    //         }
    //     }

    //     splitArr = new string[](_splitsCount);

    //     _offset = 0;
    //     _splitsCount = 0;
    //     while (_offset < _baseBytes.length - 1) {

    //         int _limit = _indexOf(_base, _value, _offset);
    //         if (_limit == - 1) {
    //             _limit = int(_baseBytes.length);
    //         }

    //         string memory _tmp = new string(uint(_limit) - _offset);
    //         bytes memory _tmpBytes = bytes(_tmp);

    //         uint j = 0;
    //         for (uint i = _offset; i < uint(_limit); i++) {
    //             _tmpBytes[j++] = _baseBytes[i];
    //         }
    //         _offset = uint(_limit) + 1;
    //         splitArr[_splitsCount++] = string(_tmpBytes);
    //     }
    //     return splitArr;
    // }
    
    // function _indexOf(string memory _base, string memory _value, uint _offset)
    //     internal
    //     pure
    //     returns (int) {
    //     bytes memory _baseBytes = bytes(_base);
    //     bytes memory _valueBytes = bytes(_value);

    //     assert(_valueBytes.length == 1);

    //     for (uint i = _offset; i < _baseBytes.length; i++) {
    //         if (_baseBytes[i] == _valueBytes[0]) {
    //             return int(i);
    //         }
    //     }

    //     return -1;
    // }
//}

// contract DateTime {
//         /*
//          *  Date and Time utilities for ethereum contracts
//          *
//          */
//         struct _DateTime {
//                 uint16 year;
//                 uint8 month;
//                 uint8 day;
//                 uint8 hour;
//                 uint8 minute;
//                 uint8 second;
//                 uint8 weekday;
//         }

//         uint constant DAY_IN_SECONDS = 86400;
//         uint constant YEAR_IN_SECONDS = 31536000;
//         uint constant LEAP_YEAR_IN_SECONDS = 31622400;

//         uint constant HOUR_IN_SECONDS = 3600;
//         uint constant MINUTE_IN_SECONDS = 60;

//         uint16 constant ORIGIN_YEAR = 1970;

//         function isLeapYear(uint16 year) public pure returns (bool) {
//                 if (year % 4 != 0) {
//                         return false;
//                 }
//                 if (year % 100 != 0) {
//                         return true;
//                 }
//                 if (year % 400 != 0) {
//                         return false;
//                 }
//                 return true;
//         }

//         function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
//                 return toTimestamp(year, month, day, 0, 0, 0);
//         }

//         function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
//                 return toTimestamp(year, month, day, hour, 0, 0);
//         }

//         function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
//                 return toTimestamp(year, month, day, hour, minute, 0);
//         }

//         function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
//                 uint16 i;

//                 // Year
//                 for (i = ORIGIN_YEAR; i < year; i++) {
//                         if (isLeapYear(i)) {
//                                 timestamp += LEAP_YEAR_IN_SECONDS;
//                         }
//                         else {
//                                 timestamp += YEAR_IN_SECONDS;
//                         }
//                 }

//                 // Month
//                 uint8[12] memory monthDayCounts;
//                 monthDayCounts[0] = 31;
//                 if (isLeapYear(year)) {
//                         monthDayCounts[1] = 29;
//                 }
//                 else {
//                         monthDayCounts[1] = 28;
//                 }
//                 monthDayCounts[2] = 31;
//                 monthDayCounts[3] = 30;
//                 monthDayCounts[4] = 31;
//                 monthDayCounts[5] = 30;
//                 monthDayCounts[6] = 31;
//                 monthDayCounts[7] = 31;
//                 monthDayCounts[8] = 30;
//                 monthDayCounts[9] = 31;
//                 monthDayCounts[10] = 30;
//                 monthDayCounts[11] = 31;

//                 for (i = 1; i < month; i++) {
//                         timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
//                 }

//                 // Day
//                 timestamp += DAY_IN_SECONDS * (day - 1);

//                 // Hour
//                 timestamp += HOUR_IN_SECONDS * (hour);

//                 // Minute
//                 timestamp += MINUTE_IN_SECONDS * (minute);

//                 // Second
//                 timestamp += second;

//                 return timestamp;
//         }
// }