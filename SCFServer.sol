// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

contract SCFCustomerOperations {
    // BookingStatus - 
    enum SCFBookingStatus {UNACCEPTED, INITIATED, PAID, CONFIRMED, AIRLINE_CANCELLED, USER_CANCELLED, REFUND_INITIATED, REFUND_COMPLETED, COMPLETED}
    
    struct SCFCustomerData {
        address airline; // Address of the airlines
        
        //bytes32 initiator_hash; // Hashed choice of the initiator
        //uint8 initiator_choice; // Raw number of initiator's choice - 1 for Rock, 2 for Paper, 3 for Scissors
       // string initiator_random_str; // Random string chosen by the initiator
        
	    address customer; // Address of the customer
		SCFBookingStatus booking_status; // current status of the booking
        uint8 penalty_percentage; //percentage to be deducted as penalty in case of cancellation
        uint256 booking_charge; // flight booking charge
        string comment; // Comment specifying the current status of the booking
        bytes32 bookingID; //unique code generated to track each booking
    }
    
    SCFCustomerData _customerData;
    
    constructor(address _airline, address _customer) {
            _customerData = SCFCustomerData({
                                    airline: _airline,
                                    customer: _customer,
                                    booking_status: SCFBookingStatus.UNACCEPTED,
                                    penalty_percentage: 0,
                                    booking_charge: 0,
                                    comment: '',
                                    bookingID: 0
                                });
    }
    
    function initiateBooking(uint32 _flightNo, uint8 _seatCategory, uint256 _bookingDate) public payable returns (bool) {
        // Generate unique booking id and transfer ether to contract
        //return _customerData.bookingID;
        return true;
    }
    
    function cancelBooking(bytes32 _bookingID) public returns (bool) {
        // TBD: Refer doc
        return true;
    }
    
    function claimRefund(bytes32 _bookingID) public returns (bool) {
        // TBD: Refer doc
        return true;
    }
    
    function getBookingStatus(bytes32 _bookingID) public view returns (SCFBookingStatus) {
        return _customerData.booking_status;
        
    }
}

contract SCFAirlineOperations {
    // FlightStatus
    enum SCFFlightStatus {UNKNOWN, ON_TIME, DELAY, CANCELLED, COMPLETED}
    
    struct SCFFlightData {
        address airline; 
        uint32 flight_number;
        uint256 flight_date;
        string from_city;
        string to_city;
        SCFFlightStatus flight_status;
    }
    SCFFlightData _flightData;
    
    constructor(address _airline, uint32 _flightNo) {
        _flightData = SCFFlightData({
                                    airline: _airline,
                                    flight_number: _flightNo,
                                    flight_date: 0, 
                                    from_city: '',
                                    to_city: '',
                                    flight_status: SCFFlightStatus.UNKNOWN
                                });
    }
                                
    function updateFlightStatus(uint32 _flightNo, uint8 _flightStatus) public returns (bool) {
        return true;
    }  
    
    function getSeatPrice(uint32 _flightNo, uint8 _seatCategory) public view returns (uint256 amount) {
        return 0;
        
    }
    
    function getFlightStatus(uint32 _flightNo) public view returns (SCFFlightStatus) {
        return _flightData.flight_status;
    }
    
    
}
   
contract SCFServer {
    // Mapping for each customerOperations instance with the first address being the airline  and internal key aaddress being the customer
    mapping(address => mapping(address => SCFCustomerOperations)) _customerList;
    
    //Mapping for each AirlineOperations instance with the first address being the airline and internal mapping is wrt flightNo
    mapping(address => mapping(uint32 => SCFAirlineOperations)) _flightList;
    
    constructor(uint32 _flightNo1, uint32 _flightNo2) {
       
        SCFAirlineOperations airline1 = new SCFAirlineOperations(msg.sender, _flightNo1);
        _flightList[msg.sender][_flightNo1] = airline1;
        
        SCFAirlineOperations airline2 = new SCFAirlineOperations(msg.sender, _flightNo2);
        _flightList[msg.sender][_flightNo2] = airline2;
        
    }
    
    // Airline setup to register each customer and simulate the list of flights, each loaded with its specific flight data
    function initiateOperation(address _customer) public {
        SCFCustomerOperations customer = new SCFCustomerOperations(msg.sender, _customer);
        _customerList[msg.sender][_customer] = customer;
    }

    // Customer operation:    
    function initiateBooking(address _airline, uint32 _flightNo, uint8 _seatCategory, uint256 _bookingDate) public returns (bool) {
        //bytes32 _bookingID;
        
        SCFCustomerOperations customer = _customerList[_airline][msg.sender];
        //SCFAirlineOperations airlines = _flightList[_airline][_flightNo];
        
        return customer.initiateBooking(_flightNo, _seatCategory, _bookingDate);
        
        //return (_bookingID, airlines._flightData);
    }

    // Customer operation:  
    function cancelBooking(address _airline, bytes32 _bookingID) public returns (bool) {
        SCFCustomerOperations customer = _customerList[_airline][msg.sender];
        return customer.cancelBooking(_bookingID);
    }

    // Customer operation:  
    function claimRefund(address _airline, bytes32 _bookingID) public returns (bool) {
        SCFCustomerOperations customer = _customerList[_airline][msg.sender];
        return customer.claimRefund(_bookingID);
    }
    
    // Airline operation:
    function updateFlightStatus(uint32 _flightNo, uint8 _flightStatus) public returns (bool){
        SCFAirlineOperations airlines = _flightList[msg.sender][_flightNo];
        return airlines.updateFlightStatus(_flightNo, _flightStatus);
    }
    
    // Get functions
    function getSeatPrice(address _airline, uint32 _flightNo, uint8 _seatCategory) public view returns (uint256 amount) {
        SCFAirlineOperations airlines = _flightList[_airline][_flightNo];
        return airlines.getSeatPrice(_flightNo, _seatCategory);
    }

    
    function getBookingStatus(address _airline, address _customer, bytes32 _bookingID) public view returns (SCFCustomerOperations.SCFBookingStatus) {
        SCFCustomerOperations customer = _customerList[_airline][_customer];
        return customer.getBookingStatus(_bookingID);
    }
    
    function getFlightStatus(address _airline, address _customer, uint32 _flightNo) public view returns (SCFAirlineOperations.SCFFlightStatus) {
        SCFAirlineOperations airlines = _flightList[_airline][_flightNo];
        return airlines.getFlightStatus(_flightNo);
    }
}







