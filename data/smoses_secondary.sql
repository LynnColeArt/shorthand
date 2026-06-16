# phpMyAdmin SQL Dump
# version 2.5.2
# http://www.phpmyadmin.net
#
# Host: localhost
# Generation Time: Feb 08, 2004 at 02:39 AM
# Server version: 4.0.15
# PHP Version: 4.2.3
# 
# Database : `smoses_secondary`
# 

# --------------------------------------------------------

#
# Table structure for table `cart_categories`
#
# Creation: Jan 30, 2004 at 12:16 PM
# Last update: Jan 30, 2004 at 12:16 PM
#

DROP TABLE IF EXISTS `cart_categories`;
CREATE TABLE `cart_categories` (
  `CategoryID` int(11) NOT NULL auto_increment,
  `CategoryName` varchar(50) default NULL,
  PRIMARY KEY  (`CategoryID`)
) TYPE=MyISAM AUTO_INCREMENT=22 ;

#
# Dumping data for table `cart_categories`
#

INSERT INTO `cart_categories` VALUES (14, 'Communication Tools');
INSERT INTO `cart_categories` VALUES (15, 'Deception');
INSERT INTO `cart_categories` VALUES (16, 'Travel');
INSERT INTO `cart_categories` VALUES (17, 'Protection');
INSERT INTO `cart_categories` VALUES (18, 'Munitions');
INSERT INTO `cart_categories` VALUES (19, 'Tools');
INSERT INTO `cart_categories` VALUES (20, 'General');
INSERT INTO `cart_categories` VALUES (21, 'Empty Category');

# --------------------------------------------------------

#
# Table structure for table `cart_configuration`
#
# Creation: Jan 30, 2004 at 12:16 PM
# Last update: Jan 30, 2004 at 12:16 PM
#

DROP TABLE IF EXISTS `cart_configuration`;
CREATE TABLE `cart_configuration` (
  `autoid` int(3) NOT NULL default '0',
  `primary_color` varchar(6) NOT NULL default '#fffff',
  `secondary_color` varchar(6) NOT NULL default '#e1e1e',
  `code_thumbnail` varchar(255) NOT NULL default '',
  `thumbnails` tinyint(1) NOT NULL default '0',
  `allow_subs` tinyint(1) NOT NULL default '0',
  `reviews` tinyint(1) NOT NULL default '0',
  `alsobought` tinyint(1) NOT NULL default '0',
  `currency` char(1) NOT NULL default '0',
  `title` varchar(255) default '0',
  `desc_length` tinyint(3) NOT NULL default '0',
  PRIMARY KEY  (`autoid`)
) TYPE=MyISAM;

#
# Dumping data for table `cart_configuration`
#

INSERT INTO `cart_configuration` VALUES (1, 'fffccc', 'ffffff', '', 0, 0, 1, 0, '$', 'Test Site', 127);

# --------------------------------------------------------

#
# Table structure for table `cart_customers`
#
# Creation: Jan 30, 2004 at 12:16 PM
# Last update: Jan 30, 2004 at 12:16 PM
#

DROP TABLE IF EXISTS `cart_customers`;
CREATE TABLE `cart_customers` (
  `CustomerID` int(11) NOT NULL auto_increment,
  `FullName` varchar(50) default NULL,
  `EmailAddress` varchar(50) default NULL,
  `Password` varchar(50) default NULL,
  PRIMARY KEY  (`CustomerID`)
) TYPE=MyISAM AUTO_INCREMENT=29 ;

#
# Dumping data for table `cart_customers`
#

INSERT INTO `cart_customers` VALUES (1, 'James Bondwell', 'jb@ibuyspy.com', 'IBS_007');
INSERT INTO `cart_customers` VALUES (2, 'Sarah Goodpenny', 'sg@ibuyspy.com', 'IBS_001');
INSERT INTO `cart_customers` VALUES (3, 'Gordon Que', 'gq@ibuyspy.com', 'IBS_000');
INSERT INTO `cart_customers` VALUES (19, 'Guest Account', 'guest', 'guest');
INSERT INTO `cart_customers` VALUES (16, 'Test Account', 'd', 'd');
INSERT INTO `cart_customers` VALUES (20, 'Fredrick Bartlett', 'rick_b@WeDoNet.net', '74591234');
INSERT INTO `cart_customers` VALUES (21, 'Rick Bartlett', '74590000', 'palmtreefrb@WeDoNet.net');
INSERT INTO `cart_customers` VALUES (22, 'sdasd', '', '');
INSERT INTO `cart_customers` VALUES (23, 'John Doe', 'jd@WeDoNet.net', '123123123');
INSERT INTO `cart_customers` VALUES (24, 'Jane Doe', 'Jane_doe@WeDoNet.net', '1234');
INSERT INTO `cart_customers` VALUES (25, 'werawrawer', 'sadasd@awsrdr.net', '1234');
INSERT INTO `cart_customers` VALUES (26, 'adasd', 'asdasd@qwqw.net', '123');
INSERT INTO `cart_customers` VALUES (27, 'wadaweawe', 'wqeqwe@asd.com', '1234');
INSERT INTO `cart_customers` VALUES (28, 'rb', 'x@x.net', 'x');

# --------------------------------------------------------

#
# Table structure for table `cart_orderdetails`
#
# Creation: Jan 30, 2004 at 12:16 PM
# Last update: Feb 06, 2004 at 09:32 PM
#

DROP TABLE IF EXISTS `cart_orderdetails`;
CREATE TABLE `cart_orderdetails` (
  `autoid` int(11) NOT NULL auto_increment,
  `orderstate` int(1) NOT NULL default '0',
  `OrderID` varchar(50) NOT NULL default '0',
  `ProductID` int(11) NOT NULL default '0',
  `Quantity` int(11) default '0',
  PRIMARY KEY  (`autoid`)
) TYPE=MyISAM AUTO_INCREMENT=74 ;

#
# Dumping data for table `cart_orderdetails`
#

INSERT INTO `cart_orderdetails` VALUES (1, 0, 'gw5AD', 386, 10);
INSERT INTO `cart_orderdetails` VALUES (2, 0, 'gw5AD', 368, 3);
INSERT INTO `cart_orderdetails` VALUES (3, 0, 'BzhoXmsGQTNYJKge', 363, 1);
INSERT INTO `cart_orderdetails` VALUES (4, 0, 'vQ4IA0nirOPKlnVo', 364, 5);
INSERT INTO `cart_orderdetails` VALUES (5, 0, 'BzhoXmsGQTNYJKge', 362, 7);
INSERT INTO `cart_orderdetails` VALUES (6, 0, 'BzhoXmsGQTNYJKge', 364, 3);
INSERT INTO `cart_orderdetails` VALUES (7, 0, 'CVbwSXKetQCkPm2N', 360, 9);
INSERT INTO `cart_orderdetails` VALUES (16, 0, 'rmFFCwlrH5mtqj2R', 404, 3);
INSERT INTO `cart_orderdetails` VALUES (20, 0, 'wUEQofjuQxVc0OQ5', 386, 1);
INSERT INTO `cart_orderdetails` VALUES (18, 0, 'rmFFCwlrH5mtqj2R', 374, 1);
INSERT INTO `cart_orderdetails` VALUES (13, 0, 'CVbwSXKetQCkPm2N', 401, 1);
INSERT INTO `cart_orderdetails` VALUES (15, 0, 'CVbwSXKetQCkPm2N', 377, 1);
INSERT INTO `cart_orderdetails` VALUES (21, 0, 'wUEQofjuQxVc0OQ5', 374, 1);
INSERT INTO `cart_orderdetails` VALUES (22, 0, 'Fee0pWGOKL4AEGLM', 394, 1);
INSERT INTO `cart_orderdetails` VALUES (23, 0, 'UlRksrTiZVXgBgKv', 379, 1);
INSERT INTO `cart_orderdetails` VALUES (24, 0, '5lWWRtcId5YsLeJF', 386, 1);
INSERT INTO `cart_orderdetails` VALUES (33, 0, 'LqEW5ulYowzGxZjV', 387, 1);
INSERT INTO `cart_orderdetails` VALUES (32, 0, 'LqEW5ulYowzGxZjV', 357, 7);
INSERT INTO `cart_orderdetails` VALUES (30, 0, 'Q04oHE0sFtCnevMq', 378, 2);
INSERT INTO `cart_orderdetails` VALUES (34, 0, 'LqEW5ulYowzGxZjV', 379, 1);
INSERT INTO `cart_orderdetails` VALUES (54, 0, 'jDdh6swTOSWvQ0QX', 363, 1);
INSERT INTO `cart_orderdetails` VALUES (53, 0, 'jDdh6swTOSWvQ0QX', 386, 84);
INSERT INTO `cart_orderdetails` VALUES (52, 0, 'jDdh6swTOSWvQ0QX', 360, 4);
INSERT INTO `cart_orderdetails` VALUES (51, 0, 'bNnuuLeQOIshMc4E', 374, 1);
INSERT INTO `cart_orderdetails` VALUES (50, 0, 'bNnuuLeQOIshMc4E', 393, 1);
INSERT INTO `cart_orderdetails` VALUES (57, 0, 'YhDXi2gIT2tAHynY', 9362, 1);
INSERT INTO `cart_orderdetails` VALUES (58, 0, 'YhDXi2gIT2tAHynY', 385, 1);
INSERT INTO `cart_orderdetails` VALUES (59, 0, 'YhDXi2gIT2tAHynY', 370, 2);
INSERT INTO `cart_orderdetails` VALUES (60, 0, 'YhDXi2gIT2tAHynY', 390, 1);
INSERT INTO `cart_orderdetails` VALUES (61, 0, 'YFriDOGERfMS6tld', 9356, 1);
INSERT INTO `cart_orderdetails` VALUES (63, 0, 'JSVyP5IuY11H0qrj', 9359, 1);
INSERT INTO `cart_orderdetails` VALUES (67, 0, 'JSVyP5IuY11H0qrj', 362, 1);
INSERT INTO `cart_orderdetails` VALUES (65, 0, 'JSVyP5IuY11H0qrj', 356, 1);
INSERT INTO `cart_orderdetails` VALUES (66, 0, 'JSVyP5IuY11H0qrj', 359, 6);
INSERT INTO `cart_orderdetails` VALUES (68, 0, 'JSVyP5IuY11H0qrj', 357, 1);
INSERT INTO `cart_orderdetails` VALUES (69, 0, 'JSVyP5IuY11H0qrj', 367, 1);
INSERT INTO `cart_orderdetails` VALUES (70, 0, 'JSVyP5IuY11H0qrj', 371, 1);
INSERT INTO `cart_orderdetails` VALUES (73, 0, 'giuTSunemyl0jZbf', 387, 1);

# --------------------------------------------------------

#
# Table structure for table `cart_orders`
#
# Creation: Jan 30, 2004 at 12:16 PM
# Last update: Jan 30, 2004 at 12:16 PM
#

DROP TABLE IF EXISTS `cart_orders`;
CREATE TABLE `cart_orders` (
  `OrderID` varchar(50) NOT NULL default '',
  `CustomerID` int(11) default '0',
  `OrderDate` timestamp(14) NOT NULL,
  `ShipDate` datetime default '0000-00-00 00:00:00',
  PRIMARY KEY  (`OrderID`)
) TYPE=MyISAM;

#
# Dumping data for table `cart_orders`
#

INSERT INTO `cart_orders` VALUES ('99', 19, 20000706010100, '2000-07-07 01:01:00');
INSERT INTO `cart_orders` VALUES ('93', 16, 20000703010100, '2000-07-04 01:01:00');
INSERT INTO `cart_orders` VALUES ('101', 16, 20000710010100, '2000-07-11 01:01:00');
INSERT INTO `cart_orders` VALUES ('103', 16, 20000710010100, '2000-07-10 01:01:00');
INSERT INTO `cart_orders` VALUES ('96', 19, 20000703010100, '2000-07-03 01:01:00');
INSERT INTO `cart_orders` VALUES ('104', 19, 20000710010100, '2000-07-11 01:01:00');
INSERT INTO `cart_orders` VALUES ('105', 16, 20001030010100, '2000-10-31 01:01:00');
INSERT INTO `cart_orders` VALUES ('106', 16, 20001030010100, '2000-10-30 01:01:00');
INSERT INTO `cart_orders` VALUES ('120', 20, 20020311000000, '2002-03-13 00:00:00');
INSERT INTO `cart_orders` VALUES ('100', 19, 20000706010100, '2000-07-08 01:01:00');
INSERT INTO `cart_orders` VALUES ('102', 16, 20000710010100, '2000-07-12 01:01:00');
INSERT INTO `cart_orders` VALUES ('131', 20, 20020312091319, '2002-03-14 09:13:19');
INSERT INTO `cart_orders` VALUES ('132', 20, 20020314081355, '2002-03-15 08:13:55');
INSERT INTO `cart_orders` VALUES ('126', 20, 00000000000000, '0000-00-00 00:00:00');
INSERT INTO `cart_orders` VALUES ('130', 20, 20020312025341, '2002-03-14 02:53:41');
INSERT INTO `cart_orders` VALUES ('129', 20, 20020312022740, '2002-03-14 02:27:40');
INSERT INTO `cart_orders` VALUES ('128', 20, 20020311085956, '2002-03-12 08:59:56');
INSERT INTO `cart_orders` VALUES ('127', 20, 20020311083632, '2002-03-11 08:36:32');

# --------------------------------------------------------

#
# Table structure for table `cart_products`
#
# Creation: Feb 01, 2004 at 06:43 PM
# Last update: Feb 01, 2004 at 06:43 PM
#

DROP TABLE IF EXISTS `cart_products`;
CREATE TABLE `cart_products` (
  `ProductID` int(11) NOT NULL auto_increment,
  `CategoryID` int(11) default '0',
  `ModelNumber` varchar(50) default NULL,
  `ModelName` varchar(50) default NULL,
  `ProductImage` varchar(50) default NULL,
  `ProductStatus` int(1) NOT NULL default '1',
  `Productstock` int(11) NOT NULL default '0',
  `UnitCost` decimal(19,4) default '0.0000',
  `Description` text,
  PRIMARY KEY  (`ProductID`)
) TYPE=MyISAM AUTO_INCREMENT=9367 ;

#
# Dumping data for table `cart_products`
#

INSERT INTO `cart_products` VALUES (355, 16, 'RU007', 'Rain Racer 2000', 'image.gif', 1, 0, '1499.9900', 'Looks like an ordinary bumbershoot, but don\'t be fooled! Simply place Rain Racer\'s tip on the ground and press the release latch. Within seconds, this ordinary rain umbrella converts into a two-wheeled gas-powered mini-scooter. Goes from 0 to 60 in 7.5 seconds - even in a driving rain! Comes in black, blue, and candy-apple red.');
INSERT INTO `cart_products` VALUES (356, 20, 'STKY1', 'Edible Tape', 'image.gif', 1, 0, '3.9900', 'The latest in personal survival gear, the STKY1 looks like a roll of ordinary office tape, but can save your life in an emergency.  Just remove the tape roll and place in a kettle of boiling water with mixed vegetables and a ham shank. In just 90 minutes you have a great tasking soup that really sticks to your ribs! Herbs and spices not included.');
INSERT INTO `cart_products` VALUES (357, 16, 'P38', 'Escape Vehicle (Air)', 'image.gif', 1, 0, '2.9900', 'In a jam, need a quick escape? Just whip out a sheet of our patented P38 paper and, with a few quick folds, it converts into a lighter-than-air escape vehicle! Especially effective on windy days - no fuel required. Comes in several sizes including letter, legal, A10, and B52.');
INSERT INTO `cart_products` VALUES (358, 19, 'NOZ119', 'Extracting Tool', 'image.gif', 1, 0, '199.0000', 'High-tech miniaturized extracting tool. Excellent for extricating foreign objects from your person. Good for picking up really tiny stuff, too! Cleverly disguised as a pair of tweezers. ');
INSERT INTO `cart_products` VALUES (359, 16, 'PT109', 'Escape Vehicle (Water)', 'image.gif', 1, 0, '1299.9900', 'Camouflaged as stylish wing tips, these \'shoes\' get you out of a jam on the high seas instantly. Exposed to water, the pair transforms into speedy miniature inflatable rafts. Complete with 76 HP outboard motor, these hip heels will whisk you to safety even in the roughest of seas. Warning: Not recommended for beachwear.');
INSERT INTO `cart_products` VALUES (360, 14, 'RED1', 'Communications Device', 'image.gif', 1, 0, '49.9900', 'Subversively stay in touch with this miniaturized wireless communications device. Speak into the pointy end and listen with the other end! Voice-activated dialing makes calling for backup a breeze. Excellent for undercover work at schools, rest homes, and most corporate headquarters. Comes in assorted colors.');
INSERT INTO `cart_products` VALUES (362, 14, 'LK4TLNT', 'Persuasive Pencil', 'image.gif', 1, 0, '1.9900', 'Persuade anyone to see your point of view!  Captivate your friends and enemies alike!  Draw the crime-scene or map out the chain of events.  All you need is several years of training or copious amounts of natural talent. You\'re halfway there with the Persuasive Pencil. Purchase this item with the Retro Pocket Protector Rocket Pack for optimum disguise.');
INSERT INTO `cart_products` VALUES (363, 18, 'NTMBS1', 'Multi-Purpose Rubber Band', 'image.gif', 1, 0, '1.9900', 'One of our most popular items!  A band of rubber that stretches  20 times the original size. Uses include silent one-to-one communication across a crowded room, holding together a pack of Persuasive Pencils, and powering lightweight aircraft. Beware, stretching past 20 feet results in a painful snap and a rubber strip.');
INSERT INTO `cart_products` VALUES (364, 19, 'NE1RPR', 'Universal Repair System', 'image.gif', 1, 0, '4.9900', 'Few people appreciate the awesome repair possibilities contained in a single roll of duct tape. In fact, some houses in the Midwest are made entirely out of the miracle material contained in every roll! Can be safely used to repair cars, computers, people, dams, and a host of other items.');
INSERT INTO `cart_products` VALUES (365, 19, 'BRTLGT1', 'Effective Flashlight', 'image.gif', 1, 0, '9.9900', 'The most powerful darkness-removal device offered to creatures of this world.  Rather than amplifying existing/secondary light, this handy product actually REMOVES darkness allowing you to see with your own eyes.  Must-have for nighttime operations. An affordable alternative to the Night Vision Goggles.');
INSERT INTO `cart_products` VALUES (367, 18, 'INCPPRCLP', 'The Incredible Versatile Paperclip', 'image.gif', 1, 0, '1.4900', 'This 0. 01 oz piece of metal is the most versatile item in any respectable spy\'s toolbox and will come in handy in all sorts of situations. Serves as a wily lock pick, aerodynamic projectile (used in conjunction with Multi-Purpose Rubber Band), or escape-proof finger cuffs.  Best of all, small size and pliability means it fits anywhere undetected.  Order several today!');
INSERT INTO `cart_products` VALUES (368, 16, 'DNTRPR', 'Toaster Boat', 'image.gif', 1, 0, '19999.9800', 'Turn breakfast into a high-speed chase! In addition to toasting bagels and breakfast pastries, this inconspicuous toaster turns into a speedboat at the touch of a button. Boasting top speeds of 60 knots and an ultra-quiet motor, this valuable item will get you where you need to be ... fast! Best of all, Toaster Boat is easily repaired using a Versatile Paperclip or a standard butter knife. Manufacturer\'s Warning: Do not submerge electrical items.');
INSERT INTO `cart_products` VALUES (370, 17, 'TGFDA', 'Multi-Purpose Towelette', 'image.gif', 1, 0, '12.9900', 'Don\'t leave home without your monogrammed towelette! Made from lightweight, quick-dry fabric, this piece of equipment has more uses in a spy\'s day than a Swiss Army knife. The perfect all-around tool while undercover in the locker room: serves as towel, shield, disguise, sled, defensive weapon, whip and emergency food source. Handy bail gear for the Toaster Boat. Monogram included with purchase price.');
INSERT INTO `cart_products` VALUES (371, 18, 'WOWPEN', 'Mighty Mighty Pen', 'image.gif', 1, 0, '129.9900', 'Some spies claim this item is more powerful than a sword. After examining the titanium frame, built-in blowtorch, and Nerf dart-launcher, we tend to agree! ');
INSERT INTO `cart_products` VALUES (372, 20, 'ICNCU', 'Perfect-Vision Glasses', 'image.gif', 1, 0, '129.9900', 'Avoid painful and potentially devastating laser eye surgery and contact lenses. Cheaper and more effective than a visit to the optometrist, these Perfect-Vision Glasses simply slide over nose and eyes and hook on ears. Suddenly you have 20/20 vision! Glasses also function as HUD (Heads Up Display) for most European sports cars manufactured after 1992.');
INSERT INTO `cart_products` VALUES (373, 17, 'LKARCKT', 'Pocket Protector Rocket Pack', 'image.gif', 1, 0, '1.9900', 'Any debonair spy knows that this accoutrement is coming back in style. Flawlessly protects the pockets of your short-sleeved oxford from unsightly ink and pencil marks. But there\'s more! Strap it on your back and it doubles as a rocket pack. Provides enough turbo-thrust for a 250-pound spy or a passel of small children. Maximum travel radius: 3000 miles.');
INSERT INTO `cart_products` VALUES (374, 15, 'DNTGCGHT', 'Counterfeit Creation Wallet', 'image.gif', 1, 0, '999.9900', 'Don\'t be caught penniless in Prague without this hot item! Instantly creates replicas of most common currencies! Simply place rocks and water in the wallet, close, open up again, and remove your legal tender!');
INSERT INTO `cart_products` VALUES (375, 16, 'WRLD00', 'Global Navigational System', 'image.gif', 1, 0, '29.9900', 'No spy should be without one of these premium devices. Determine your exact location with a quick flick of the finger. Calculate destination points by spinning, closing your eyes, and stopping it with your index finger.');
INSERT INTO `cart_products` VALUES (376, 15, 'CITSME9', 'Cloaking Device', 'image.gif', 1, 0, '9999.9900', 'Worried about detection on your covert mission? Confuse mission-threatening forces with this cloaking device. Powerful new features include string-activated pre-programmed phrases such as "Danger! Danger!", "Reach for the sky!", and other anti-enemy expressions. Hyper-reactive karate chop action deters even the most persistent villain.');
INSERT INTO `cart_products` VALUES (377, 15, 'BME007', 'Indentity Confusion Device', 'image.gif', 1, 0, '6.9900', 'Never leave on an undercover mission without our Identity Confusion Device! If a threatening person approaches, deploy the device and point toward the oncoming individual. The subject will fail to recognize you and let you pass unnoticed. Also works well on dogs.');
INSERT INTO `cart_products` VALUES (379, 17, 'SHADE01', 'Ultra Violet Attack Defender', 'image.gif', 1, 0, '89.9900', 'Be safe and suave. A spy wearing this trendy article of clothing is safe from ultraviolet ray-gun attacks. Worn correctly, the Defender deflects rays from ultraviolet weapons back to the instigator. As a bonus, also offers protection against harmful solar ultraviolet rays, equivalent to SPF 50.');
INSERT INTO `cart_products` VALUES (378, 17, 'SQUKY1', 'Guard Dog Pacifier', 'image.gif', 1, 0, '14.9900', 'Pesky guard dogs become a spy\'s best friend with the Guard Dog Pacifier. Even the most ferocious dogs suddenly act like cuddly kittens when they see this prop.  Simply hold the device in front of any threatening dogs, shaking it mildly.  For tougher canines, a quick squeeze emits an irresistible squeak that never fails to  place the dog under your control.');
INSERT INTO `cart_products` VALUES (382, 20, 'CHEW99', 'Survival Bar', 'image.gif', 1, 0, '6.9900', 'Survive for up to four days in confinement with this handy item. Disguised as a common eraser, it\'s really a high-calorie food bar. Stranded in hostile territory without hope of nourishment? Simply break off a small piece of the eraser and chew vigorously for at least twenty minutes. Developed by the same folks who created freeze-dried ice cream, powdered drink mix, and glow-in-the-dark shoelaces.');
INSERT INTO `cart_products` VALUES (402, 20, 'C00LCMB1', 'Telescoping Comb', 'image.gif', 1, 0, '399.9900', 'Use the Telescoping Comb to track down anyone, anywhere! Deceptively simple, this is no normal comb. Flip the hidden switch and two telescoping lenses project forward creating a surprisingly powerful set of binoculars (50X). Night-vision add-on is available for midnight hour operations.');
INSERT INTO `cart_products` VALUES (384, 19, 'FF007', 'Eavesdrop Detector', 'image.gif', 1, 0, '99.9900', 'Worried that counteragents have placed listening devices in your home or office? No problem! Use our bug-sweeping wiener to check your surroundings for unwanted surveillance devices. Just wave the frankfurter around the room ... when bugs are detected, this "foot-long" beeps! Comes complete with bun, relish, mustard, and headphones for privacy.');
INSERT INTO `cart_products` VALUES (385, 16, 'LNGWADN', 'Escape Cord', 'image.gif', 1, 0, '13.9900', 'Any agent assigned to mountain terrain should carry this ordinary-looking extension cord ... except that it\'s really a rappelling rope! Pull quickly on each end to convert the electrical cord into a rope capable of safely supporting up to two agents. Comes in various sizes including Mt McKinley, Everest, and Kilimanjaro. WARNING: To prevent serious injury, be sure to disconnect from wall socket before use.');
INSERT INTO `cart_products` VALUES (386, 17, '1MOR4ME', 'Cocktail Party Pal', 'image.gif', 1, 0, '69.9900', 'Do your assignments have you flitting from one high society party to the next? Worried about keeping your wits about you as you mingle witih the champagne-and-caviar crowd? No matter how many drinks you\'re offered, you can safely operate even the most complicated heavy machinery as long as you use our model 1MOR4ME alcohol-neutralizing coaster. Simply place the beverage glass on the patented circle to eliminate any trace of alcohol in the drink.');
INSERT INTO `cart_products` VALUES (387, 20, 'SQRTME1', 'Remote Foliage Feeder', 'image.gif', 1, 0, '9.9900', 'Even spies need to care for their office plants.  With this handy remote watering device, you can water your flowers as a spy should, from the comfort of your chair.  Water your plants from up to 50 feet away.  Comes with an optional aiming system that can be mounted to the top for improved accuracy.');
INSERT INTO `cart_products` VALUES (388, 20, 'ICUCLRLY00', 'Contact Lenses', 'image.GIF', 1, 0, '59.9900', 'Traditional binoculars and night goggles can be bulky, especially for assignments in confined areas. The problem is solved with these patent-pending contact lenses, which give excellent visibility up to 100 miles. New feature: now with a night vision feature that permits you to see in complete darkness! Contacts now come in a variety of fashionable colors for coordinating with your favorite ensembles.');
INSERT INTO `cart_products` VALUES (389, 20, 'OPNURMIND', 'Telekinesis Spoon', 'image.gif', 1, 0, '2.9900', 'Learn to move things with your mind! Broaden your mental powers using this training device to hone telekinesis skills. Simply look at the device, concentrate, and repeat "There is no spoon" over and over.');
INSERT INTO `cart_products` VALUES (390, 19, 'ULOST007', 'Rubber Stamp Beacon', 'images/x-bathroom.jpg', 1, 0, '129.9900', 'With the Rubber Stamp Beacon, you\'ll never get lost on your missions again. As you proceed through complicated terrain, stamp a stationary object with this device. Once an object has been stamped, the stamp\'s patented ink will emit a signal that can be detected up to 153.2 miles away by the receiver embedded in the device\'s case. WARNING: Do not expose ink to water.');
INSERT INTO `cart_products` VALUES (391, 17, 'BSUR2DUC', 'Bullet Proof Facial Tissue', 'images/x-stove.jpg', 1, 0, '79.9900', 'Being a spy can be dangerous work. Our patented Bulletproof Facial Tissue gives a spy confidence that any bullets in the vicinity risk-free. Unlike traditional bulletproof devices, these lightweight tissues have amazingly high tensile strength. To protect the upper body, simply place a tissue in your shirt pocket. To protect the lower body, place a tissue in your pants pocket. If you do not have any pockets, be sure to check out our Bulletproof Tape. 100 tissues per box. WARNING: Bullet must not be moving for device to successfully stop penetration.');
INSERT INTO `cart_products` VALUES (393, 20, 'NOBOOBOO4U', 'Speed Bandages', 'images/x-piano.jpg', 1, 0, '3.9900', 'Even spies make mistakes.  Barbed wire and guard dogs pose a threat of injury for the active spy.  Use our special bandages on cuts and bruises to rapidly heal the injury.  Depending on the severity of the wound, the bandages can take between 10 to 30 minutes to completely heal the injury.');
INSERT INTO `cart_products` VALUES (394, 15, 'BHONST93', 'Correction Fluid', 'image.gif', 1, 0, '1.9900', 'Disguised as typewriter correction fluid, this scientific truth serum forces subjects to correct anything not perfectly true. Simply place a drop of the special correction fluid on the tip of the subject\'s nose. Within seconds, the suspect will automatically correct every lie. Effects from Correction Fluid last approximately 30 minutes per drop. WARNING: Discontinue use if skin appears irritated.');
INSERT INTO `cart_products` VALUES (396, 19, 'BPRECISE00', 'Dilemma Resolution Device', 'image.gif', 1, 0, '11.9900', 'Facing a brick wall? Stopped short at a long, sheer cliff wall?  Carry our handy lightweight calculator for just these emergencies. Quickly enter in your dilemma and the calculator spews out the best solutions to the problem.   Manufacturer Warning: Use at own risk. Suggestions may lead to adverse outcomes.');
INSERT INTO `cart_products` VALUES (397, 14, 'LSRPTR1', 'Nonexplosive Cigar', 'image.gif', 1, 0, '29.9900', 'Contrary to popular spy lore, not all cigars owned by spies explode! Best used during mission briefings, our Nonexplosive Cigar is really a cleverly-disguised, top-of-the-line, precision laser pointer. Make your next presentation a hit.');
INSERT INTO `cart_products` VALUES (399, 20, 'QLT2112', 'Document Transportation System', 'image.gif', 1, 0, '299.9900', 'Keep your stolen Top Secret documents in a place they\'ll never think to look!  This patent leather briefcase has multiple pockets to keep documents organized.  Top quality craftsmanship to last a lifetime.');
INSERT INTO `cart_products` VALUES (400, 15, 'THNKDKE1', 'Hologram Cufflinks', 'image.gif', 1, 0, '799.9900', 'Just point, and a turn of the wrist will project a hologram of you up to 100 yards away. Sneaking past guards will be child\'s play when you\'ve sent them on a wild goose chase. Note: Hologram adds ten pounds to your appearance.');
INSERT INTO `cart_products` VALUES (401, 14, 'TCKLR1', 'Fake Moustache Translator', 'image.gif', 1, 0, '599.9900', 'Fake Moustache Translator attaches between nose and mouth to double as a language translator and identity concealer. Sophisticated electronics translate your voice into the desired language. Wriggle your nose to toggle between Spanish, English, French, and Arabic. Excellent on diplomatic missions.');
INSERT INTO `cart_products` VALUES (404, 14, 'JWLTRANS6', 'Interpreter Earrings', 'image.gif', 1, 0, '459.9900', 'The simple elegance of our stylish monosex earrings accents any wardrobe, but their clean lines mask the sophisticated technology within. Twist the lower half to engage a translator function that intercepts spoken words in any language and converts them to the wearer\'s native tongue. Warning: do not use in conjunction with our Fake Moustache Translator product, as the resulting feedback loop makes any language sound like Pig Latin.');
INSERT INTO `cart_products` VALUES (406, 19, 'GRTWTCH9', 'Multi-Purpose Watch', 'images/x-busses.jpg', 1, 0, '399.9900', 'In the tradition of famous spy movies, the Multi Purpose Watch comes with every convenience! Installed with lighter, TV, camera, schedule-organizing software, MP3 player, water purifier, spotlight, and tire pump. Special feature: Displays current date and time. Kitchen sink add-on will be available in the fall of 2001.');
INSERT INTO `cart_products` VALUES (407, 0, 'test', 'test', 'test', 1, 0, '5.8800', 'test');
INSERT INTO `cart_products` VALUES (9355, 16, 'RU007', 'Mind Control Device', 'images/x-tv.gif', 1, 0, '699.9900', 'Behold, a state of the art mind control device with all of the features. Stun your friends, and alleviate any unwanted enemies with the stupendous power of mind control. This unit comes cable ready, with nifty looking feet actually built into the bottom of it. A perfect gift, this mind control device comes with a 100% satisfaction guarantee. You\'ll have your friends doing your bidding, or your money back.');
INSERT INTO `cart_products` VALUES (9356, 20, 'STKY1', 'Cacti of Death', 'images/x-cactus.gif', 1, 0, '3.9900', 'Imagine this: You\'ve captured the secret agent who has been staking out your hidden lair far too long for it to remain amusing. You\'ve finally got him tied up, thanks to the work of your evil henchmen, and now you can reveal your evil plan before he escapes and tries to bring you to justice. What better way to enjoy the moments torturing any secret agent than with the pure evil of the Cacti of Death®. These lovely Arizona grown killing machines are perfect for any occasion. Enjoy them with your friends and loved ones, or the ones you would rather be with out. Either way, a good time awaits you with these top quality items.');
INSERT INTO `cart_products` VALUES (9357, 16, 'P38', 'Personal Rocket Packs', 'images/x-board.gif', 1, 0, '2.9900', 'In a jam, need a quick escape? Just grab one of our personal hand held rocket boosters. These deceptively simple devices are the things to have when you need to be somewhere in a hurry. Complete with down home retro design elements, and patented "landing pad" these devices are not only useful, but fun at parties.');
INSERT INTO `cart_products` VALUES (9358, 19, 'NOZ119', 'Imaging Device', 'images/x-cameras.gif', 1, 0, '199.0000', 'Perfect for reconiscence missions, where you, the evil villian have to do the job yourself. Somethings just shouldn\'t be handled by henchment...');
INSERT INTO `cart_products` VALUES (9359, 16, 'PT109', 'Escape Vehicle (Water)', 'images/x-wagon.gif', 1, 0, '1299.9900', 'This lovely wagon is perfect for transporting helpless maidens to the train tracks. A trully one of a kind item.');
INSERT INTO `cart_products` VALUES (9360, 14, 'RED1', 'Space Suits', 'images/x-rover.gif', 1, 0, '499.9900', 'Imagine strolling around the moon, enjoying the cool breeze, soaking in the rays of the sun in your shiny new space suit! Yes, these state of the art lunar capable suits are a complete self contained environment specifically designed for humans. Suites come with internal heating units, oxygen tank, and your choice of silver or gold tinted visor.');
INSERT INTO `cart_products` VALUES (9361, 14, 'ew3', 'The Diabolical Tractor of Doom', 'images/x-tractor.gif', 1, 0, '9999.9900', 'Show the neighbors on the block who\'s boxx with the Diabolical Tractor of Doom! Yes, four settings ranging from mame to mutilate, this tractor is nobody\'s play toy. Also good on small to mid sized lawns.');
INSERT INTO `cart_products` VALUES (9362, 15, 'gmn', 'Egg Beater of Distruction!', 'images/x-mixer.gif', 1, 0, '49.9500', 'The egg beater of distruction is a welcome addition to any kitchen. Sporting features like retractable blades, wood chipper, and more!');
INSERT INTO `cart_products` VALUES (9366, 15, 'notimportant', 'Cow Torpedo', 'images/x-cow.gif', 1, 0, '39.9900', 'cow go moo moo, yes moo!');
