@Zigbee @Sengled @dimmer @bulb
Feature: Test of the Sengled A19 Dimmable Bulb driver
	
	These scenarios test the functionality of the Sengled A19 Dimmable Bulb driver.

Background:
	Given the ZB_Sengled_A19_Bulb.driver has been initialized
	And the device has endpoint 1


Scenario: Driver reports capabilities to platform.
	When a base:GetAttributes command is placed on the platform bus
	Then the driver should place a base:GetAttributesResponse message on the platform bus
		And the message's base:caps attribute list should be ['base', 'dev', 'devadv', 'devconn', 'devpow', 'dim', 'swit', 'devota', 'light', 'ident']
		And the message's dev:devtypehint attribute should be Light
		And the message's devadv:drivername attribute should be ZBSengledA19Bulb 
		And the message's devadv:driverversion attribute should be 1.0
		And the message's devpow:source attribute should be LINE
		And the message's devpow:linecapable attribute should be true		
		And the message's devpow:backupbatterycapable attribute should be false		
	Then both busses should be empty


Scenario: Device connected
	When the device is connected
	Then the driver should set timeout
	# reads bulb state, level, and diagnostics
	And the driver should send onoff zclReadAttributes
	And the driver should send level zclReadAttributes
	And the driver should send 0x0B05 zclReadAttributes
	# configures reporting of state, level, and diagnostics
	And the driver should send level 0x06
	And the driver should send onoff 0x06
	And the driver should send 0x0B05 0x06


# Setting just the Dimmer.brightness to 1-100 will adjust the brightness to that value and turn the bulb ON, whatever state it was previously in
@dimProc
Scenario Outline: Client sets brightness attribute of 1-100, and no switch state
	Given the capability dim:brightness is <init-brightness>
		And the capability swit:state is <init-state>
		And the driver variable targetLevel is <init-brightness>
		And the driver variable targetState is <init-state>
    When a base:SetAttributes command with the value of dim:brightness <to-brightness> is placed on the platform bus
	Then the driver should send level moveToLevel
    Then protocol bus should be empty
    Then the driver variable targetLevel should be <target-brightness>
    Then the driver variable targetState should be ON
    
	Examples:
      | init-brightness | init-state | to-brightness | target-brightness | remarks                           |
      | 10              | ON         | 50            | 50                | adjust ON device to level 50      |
      | 10              | OFF        | 50            | 50                | turn OFF device to ON at level 50 |

# Setting just the Switch.state to OFF, will turn the bulb off and leave the brightness setting at whatever brightness it was previously
@dimProc
Scenario Outline: Client sets swit:state to OFF with no dim:brightness setting
    Given the capability dim:brightness is <init-brightness>
		And the capability swit:state is <init-state>
		And the driver variable targetLevel is <init-brightness>
		And the driver variable targetState is <init-state>
	When a base:SetAttributes command with the value of swit:state OFF is placed on the platform bus
	Then the driver should send onoff off
    Then protocol bus should be empty
    Then the driver variable targetLevel should be <init-brightness>
    Then the driver variable targetState should be OFF

	Examples:
      | init-brightness | init-state | remarks                                         |
      | 10              | OFF        | turn OFF device to OFF (to make sure it is OFF) |
      | 10              | ON         | turn ON device to OFF                           |

# Setting just the Switch.state to ON, will turn the bulb on at the current Dimmer.brightness (which should be non-zero, but if it is somehow zero then the brightness will default to 100)
@dimProc
Scenario Outline: Client sets swit:state to ON with no dim:brightness setting
    Given the capability dim:brightness is <init-brightness>
		And the capability swit:state is <init-state>
		And the driver variable targetLevel is <init-brightness>
		And the driver variable targetState is <init-state>
	When a base:SetAttributes command with the value of swit:state ON is placed on the platform bus
	Then the driver should send level moveToLevel
    Then protocol bus should be empty
    Then the driver variable targetLevel should be <target-brightness>
    Then the driver variable targetState should be ON

	Examples:
      | init-brightness | init-state | target-brightness | remarks                                      |
      | 10              | OFF        | 10                | turn OFF device to ON at prev level          |
      | 10              | ON         | 10                | turn ON device to ON (to make sure it is ON) |

# Setting the Switch.state to OFF and Dimmer.brightness to 1-100 will turn the bulb OFF and set the driver brightness to the specified brightness so that value is used as the default when turned back ON
@dimProc
Scenario Outline: Client sets swit:state to OFF with a dim:brightness
    Given the capability dim:brightness is <init-brightness>
		And the capability swit:state is <init-state>
		And the driver variable targetLevel is <init-brightness>
		And the driver variable targetState is <init-state>
	When the capability method base:SetAttributes
		 And with capability swit:state is OFF
		 And with capability dim:brightness is <to-brightness>
		 And send to driver
	Then the driver should send onoff off
    Then protocol bus should be empty
    Then the driver variable targetLevel should be <target-brightness>
    Then the driver variable targetState should be OFF

	Examples:
      | init-brightness | init-state | to-brightness | target-brightness | remarks                                          |
      | 100             | OFF        | 50            | 50                | turn OFF device to OFF with new default ON level |
      | 100             | ON         | 50            | 50                | turn ON device to OFF with new default ON level  |

# Setting the Switch.state to ON and Dimmer.brightness to 1-100 will set the bulb to the specified brightness first and then turn the bulb ON (after a short delay)
@dimProc
Scenario Outline: Client sets swit:state to ON with a dim:brightness
    Given the capability dim:brightness is <init-brightness>
		And the capability swit:state is <init-state>
		And the driver variable targetLevel is <init-brightness>
		And the driver variable targetState is <init-state>
	When the capability method base:SetAttributes
		 And with capability swit:state is ON
		 And with capability dim:brightness is <to-brightness>
		 And send to driver
	Then the driver should send level moveToLevel
    Then protocol bus should be empty
    Then the driver variable targetLevel should be <target-brightness>
    Then the driver variable targetState should be ON

	Examples:
      | init-brightness | init-state | to-brightness | target-brightness | remarks                              |
      | 10              | OFF        | 50            | 50                | turn OFF device to ON at a new level |
      | 10              | ON         | 50            | 50                | turn ON device to ON at a new level  |


