-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 06, 2023 at 02:24 PM
-- Server version: 10.4.27-MariaDB
-- PHP Version: 8.2.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `boutiqa`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`user`@`localhost` PROCEDURE `addProduct` (IN `productId` VARCHAR(5), IN `productName` VARCHAR(20), IN `productDesc` VARCHAR(100), IN `productPrice` FLOAT, IN `productImage` VARCHAR(100), IN `productStock` INT(11), IN `sellerId` VARCHAR(5), IN `productCatId` VARCHAR(5))   BEGIN
    INSERT INTO product (
        productId, 
        productName, 
        productDesc, 
        productPrice, 
        productImage, 
        productStock, 
        date, 
        sellerId, 
        productCatId
    ) VALUES (
        productId, 
        productName, 
        productDesc, 
        productPrice, 
        productImage, 
        productStock, 
        CURRENT_TIMESTAMP(), 
        sellerId, 
        productCatId
    );
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `AddToCart` (IN `p_quantity` INT(11), IN `p_productId` VARCHAR(5), IN `p_orderId` VARCHAR(5), OUT `p_success` TINYINT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = 0;
    END;
    
    START TRANSACTION;
    
    INSERT INTO cart(quantity, productId, orderId)
    VALUES(p_quantity, p_productId, p_orderId);
    
    UPDATE product
    SET productStock = productStock - p_quantity
    WHERE productId = p_productId;
    
    SET p_success = 1;
    
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_customer` (IN `p_customerEmail` VARCHAR(30), IN `p_custAddLine` VARCHAR(20), IN `p_customerContact` VARCHAR(10), IN `p_custFName` VARCHAR(20), IN `p_password` VARCHAR(20), IN `p_custLName` VARCHAR(20), IN `p_custStreet` VARCHAR(20), IN `p_custCity` VARCHAR(20))   BEGIN
  DECLARE v_exists INT;
  DECLARE v_customerId VARCHAR(5);
  
  SELECT COUNT(*) INTO v_exists FROM customer WHERE customerEmail = p_customerEmail OR customerContact = p_customerContact;
  
  IF v_exists = 0 THEN
    SELECT CONCAT('c', LPAD(COALESCE(MAX(SUBSTRING(customerId, 2)), 0) + 1, 4, '0')) INTO v_customerId FROM customer;
    
    INSERT INTO customer (customerId, customerEmail, custAddLine, customerContact, custFName, password, custLName, custStreet, custCity) 
    VALUES (v_customerId, p_customerEmail, p_custAddLine, p_customerContact, p_custFName, p_password, p_custLName, p_custStreet, p_custCity);
    
    SELECT CONCAT('New customer record added with ID ', v_customerId) AS message;
  ELSE
    SELECT 'Customer with provided email or phone number already exists' AS message;
  END IF;
  
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `add_seller` (IN `p_sellerEmail` VARCHAR(30), IN `p_idCardNumber` VARCHAR(10), IN `p_businessRegNumber` VARCHAR(15), IN `p_sellerFName` VARCHAR(20), IN `p_password` VARCHAR(20), IN `p_sellerLName` VARCHAR(20))   BEGIN
  DECLARE v_exists INT;
  DECLARE v_sellerId VARCHAR(5);
  
  SELECT COUNT(*) INTO v_exists FROM seller WHERE sellerEmail = p_sellerEmail OR idCardNumber = p_idCardNumber OR businessRegNumber = p_businessRegNumber;
  
  IF v_exists = 0 THEN
    SELECT CONCAT('s', LPAD(COALESCE(MAX(SUBSTRING(sellerId, 2)), 0) + 1, 4, '0')) INTO v_sellerId FROM seller;
    
    INSERT INTO seller (sellerId, idCardNumber, businessRegNumber, sellerEmail, sellerFName, password, sellerLName) 
    VALUES (v_sellerId, p_idCardNumber, p_businessRegNumber, p_sellerEmail, p_sellerFName, SHA2(p_password, 256), p_sellerLName);
    
    SELECT CONCAT('New seller record added with ID ', v_sellerId) AS message;
  ELSE
    SELECT 'Seller with provided email, ID card number, or business registration number already exists' AS message;
  END IF;
  
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `changeProductImage` (IN `product_id` VARCHAR(5), IN `product_image` VARCHAR(100))   BEGIN
    UPDATE product
    SET productImage = product_image
    WHERE productId = product_id;
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `DeleteCartItem` (IN `p_productId` VARCHAR(5), IN `p_orderId` VARCHAR(5), OUT `p_success` TINYINT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = 0;
    END;
    
    START TRANSACTION;
    
    -- get the quantity of the item to be deleted
    SELECT quantity INTO @deleted_quantity FROM cart WHERE productId = p_productId AND orderId = p_orderId;
    
    -- delete the item from the cart
    DELETE FROM cart WHERE productId = p_productId AND orderId = p_orderId;
    
    -- increase the product stock by the deleted quantity
    UPDATE product
    SET productStock = productStock + @deleted_quantity
    WHERE productId = p_productId;
    
    SET p_success = 1;
    
    COMMIT;
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `EditCart` (IN `p_quantity` INT(11), IN `p_productId` VARCHAR(5), IN `p_orderId` VARCHAR(5), OUT `p_success` TINYINT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = 0;
    END;
    
    START TRANSACTION;
    
    -- get the current quantity in the cart for this product
    SELECT quantity INTO @current_quantity FROM cart WHERE productId = p_productId AND orderId = p_orderId;
    
    -- if the new quantity is greater than the current quantity, reduce the product stock
    IF p_quantity > @current_quantity THEN
        UPDATE product
        SET productStock = productStock - (p_quantity - @current_quantity)
        WHERE productId = p_productId;
    -- if the new quantity is less than the current quantity, increase the product stock
    ELSEIF p_quantity < @current_quantity THEN
        UPDATE product
        SET productStock = productStock + (@current_quantity - p_quantity)
        WHERE productId = p_productId;
    END IF;
    
    -- check if product stock is less than 0, set to 0
    UPDATE product
    SET productStock = 0
    WHERE productId = p_productId AND productStock < 0;
    
    -- update the quantity in the cart
    UPDATE cart
    SET quantity = p_quantity
    WHERE productId = p_productId AND orderId = p_orderId;
    
    SET p_success = 1;
    
    COMMIT;
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `ResetSellerPassword` (IN `p_sellerEmail` VARCHAR(30), IN `p_currentPassword` VARCHAR(20), IN `p_newPassword` VARCHAR(20))   BEGIN
    DECLARE v_sellerId VARCHAR(5);
    DECLARE v_storedPassword VARCHAR(20);
    DECLARE v_currentPasswordHash VARCHAR(20);
    DECLARE v_newPasswordHash VARCHAR(20);
    
    SELECT sellerId, password INTO v_sellerId, v_storedPassword FROM seller WHERE sellerEmail = p_sellerEmail;
    
    IF v_sellerId IS NULL THEN
        SELECT 'No seller found with the provided email' AS message;
    ELSE
        SET v_currentPasswordHash = SHA2(p_currentPassword, 256);
        SET v_newPasswordHash = SHA2(p_newPassword, 256);
        
        IF BINARY v_storedPassword = v_currentPasswordHash THEN
            UPDATE seller SET password = v_newPasswordHash WHERE sellerId = v_sellerId;
            SELECT 'Password updated successfully' AS message;
        ELSE
            SELECT 'Incorrect current password' AS message;
        END IF;
    END IF;
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `SearchProductByName` (IN `p_productName` VARCHAR(20))   BEGIN
    SELECT * FROM product WHERE productName LIKE CONCAT('%', p_productName, '%');
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `UpdateCustomerProfile` (IN `p_customerId` VARCHAR(5), IN `p_customerEmail` VARCHAR(30), IN `p_custAddLine` VARCHAR(20), IN `p_customerContact` VARCHAR(10), IN `p_custFName` VARCHAR(20), IN `p_custLName` VARCHAR(20), IN `p_custStreet` VARCHAR(20), IN `p_custCity` VARCHAR(20))   BEGIN
    UPDATE customer
    SET 
        customerEmail = COALESCE(p_customerEmail, customerEmail),
        custAddLine = COALESCE(p_custAddLine, custAddLine),
        customerContact = COALESCE(p_customerContact, customerContact),
        custFName = COALESCE(p_custFName, custFName),
        custLName = COALESCE(p_custLName, custLName),
        custStreet = COALESCE(p_custStreet, custStreet),
        custCity = COALESCE(p_custCity, custCity)
    WHERE customerId = p_customerId;
END$$

CREATE DEFINER=`user`@`localhost` PROCEDURE `UpdateSellerProfile` (IN `p_sellerId` VARCHAR(5), IN `p_idCardNumber` VARCHAR(10), IN `p_businessRegNumber` VARCHAR(15), IN `p_sellerEmail` VARCHAR(30), IN `p_sellerFName` VARCHAR(20), IN `p_sellerLName` VARCHAR(20))   BEGIN
    UPDATE seller
    SET
        idCardNumber = COALESCE(p_idCardNumber, idCardNumber),
        businessRegNumber = COALESCE(p_businessRegNumber, businessRegNumber),
        sellerEmail = COALESCE(p_sellerEmail, sellerEmail),
        sellerFName = COALESCE(p_sellerFName, sellerFName),
        sellerLName = COALESCE(p_sellerLName, sellerLName)
    WHERE sellerId = p_sellerId;
END$$

--
-- Functions
--
CREATE DEFINER=`user`@`localhost` FUNCTION `CheckSellerCredentials` (`p_sellerEmail` VARCHAR(30), `p_password` VARCHAR(20)) RETURNS TINYINT(1)  BEGIN
    DECLARE v_sellerId VARCHAR(5);
    DECLARE v_storedPassword VARCHAR(256);
    
    SELECT sellerId, password INTO v_sellerId, v_storedPassword FROM seller WHERE sellerEmail = p_sellerEmail;
    
    IF v_sellerId IS NULL THEN
        RETURN FALSE;
    ELSEIF BINARY v_storedPassword = SHA2(p_password,256) THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END$$

CREATE DEFINER=`user`@`localhost` FUNCTION `check_credentials` (`email` VARCHAR(30), `password` VARCHAR(20)) RETURNS INT(11)  BEGIN
    DECLARE matches INT;
    SELECT COUNT(*) INTO matches FROM customer
    WHERE customerEmail = email AND password = password;
    RETURN matches;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `badmin`
--

CREATE TABLE `badmin` (
  `adminId` varchar(5) NOT NULL,
  `adminEmail` varchar(30) NOT NULL,
  `password` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `badmin`
--

INSERT INTO `badmin` (`adminId`, `adminEmail`, `password`) VALUES
('a001', 'pfrood0@pbs.org', '7qKmEsF'),
('a002', 'wwoodworth1@admin.ch', 'ywfWZ4hm3H'),
('a003', 'spresdie2@freewebs.com', '3pMBaL'),
('a004', 'asancroft3@umich.edu', 'ZkagQLO4tKLp'),
('a005', 'fserginson4@blogs.com', 'nr1ZBIll');

-- --------------------------------------------------------

--
-- Table structure for table `bulkemail`
--

CREATE TABLE `bulkemail` (
  `bulkEmailId` varchar(5) NOT NULL,
  `bulkstatus` tinyint(1) NOT NULL,
  `timestamp` date DEFAULT NULL,
  `emailContent` varchar(100) NOT NULL,
  `emailTopic` varchar(20) NOT NULL,
  `adminId` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bulkemail`
--

INSERT INTO `bulkemail` (`bulkEmailId`, `bulkstatus`, `timestamp`, `emailContent`, `emailTopic`, `adminId`) VALUES
('bu001', 0, '0000-00-00', 'Reattachment of Left Upper Eyelid, External Approach', 'Oth comp of fb acc l', 'a001'),
('bu002', 1, '2022-09-02', 'Revision of Infusion Device in Cisterna Chyli, Percutaneous Endoscopic Approach', 'Gonococcal infection', 'a002'),
('bu003', 0, '0000-00-00', 'Bypass Left Subclavian Artery to Left Lower Arm Artery, Open Approach', 'Burn of 3rd deg mu s', 'a003'),
('bu004', 1, '2022-02-20', 'Destruction of Left Lung, Percutaneous Approach', 'Rheu arthritis of ri', 'a004'),
('bu005', 0, '0000-00-00', 'Removal of Extraluminal Device from Urethra, Via Natural or Artificial Opening Endoscopic', 'Contusion of oth int', 'a005');

-- --------------------------------------------------------

--
-- Table structure for table `cart`
--

CREATE TABLE `cart` (
  `quantity` int(11) NOT NULL,
  `productId` varchar(5) NOT NULL,
  `orderId` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cart`
--

INSERT INTO `cart` (`quantity`, `productId`, `orderId`) VALUES
(2, 'p0001', 'o0001'),
(2, 'p0001', 'o0002'),
(0, 'p0001', 'o0005'),
(1, 'p0002', 'o0002'),
(1, 'p0003', 'o0002');

-- --------------------------------------------------------

--
-- Table structure for table `corder`
--

CREATE TABLE `corder` (
  `orderId` varchar(5) NOT NULL,
  `orderStatus` tinyint(1) NOT NULL,
  `orderBeginingDate` date NOT NULL,
  `orderStartDate` date NOT NULL,
  `customerId` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `corder`
--

INSERT INTO `corder` (`orderId`, `orderStatus`, `orderBeginingDate`, `orderStartDate`, `customerId`) VALUES
('o0001', 0, '2022-02-02', '2022-04-25', 'c0001'),
('o0002', 0, '2022-02-14', '2022-02-15', 'c0002'),
('o0003', 0, '2022-02-16', '2022-02-18', 'c0003'),
('o0004', 0, '2022-02-17', '2022-02-19', 'c0004'),
('o0005', 1, '2022-02-20', '0000-00-00', 'c0005');

-- --------------------------------------------------------

--
-- Table structure for table `custmanage`
--

CREATE TABLE `custmanage` (
  `custmanageId` varchar(5) NOT NULL,
  `action` varchar(10) NOT NULL,
  `adminId` varchar(5) NOT NULL,
  `customerId` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `custmanage`
--

INSERT INTO `custmanage` (`custmanageId`, `action`, `adminId`, `customerId`) VALUES
('m001', 'add', 'a001', 'c0002'),
('sm000', 'activated', 'a001', 'c0001'),
('sm001', 'activated', 'a001', 'c0001'),
('sm002', 'activated', 'a002', 'c0002'),
('sm003', 'activated', 'a003', 'c0003'),
('sm004', 'activated', 'a004', 'c0004'),
('sm005', 'activated', 'a005', 'c0005');

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `customerId` varchar(5) NOT NULL,
  `customerEmail` varchar(30) NOT NULL,
  `custAddLine` varchar(20) NOT NULL,
  `customerContact` varchar(10) NOT NULL,
  `custFName` varchar(20) NOT NULL,
  `password` varchar(20) NOT NULL,
  `custLName` varchar(20) NOT NULL,
  `custStreet` varchar(20) NOT NULL,
  `custCity` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`customerId`, `customerEmail`, `custAddLine`, `customerContact`, `custFName`, `password`, `custLName`, `custStreet`, `custCity`) VALUES
('c0001', 'new_email@example.com', '50 Cody Point', '1234567890', 'Coralie', 'lymAWgdlsAK6', 'Lanfear', 'Cody', 'Point'),
('c0002', 'dfollett1@pinterest.com', '723 Esch Crossing', '97863223', 'Dael', 'nZo6MCIjbt', 'Follett', 'Esch', 'Crossing'),
('c0003', 'hklain2@howstuffworks.com', '2 Coleman Drive', '79912428', 'Heriberto', 'w7MkhNmb6J', 'Klain', 'Coleman', 'Drive'),
('c0004', 'atoffano3@nyu.edu', '72 Talmadge Alley', '42438021', 'August', 'N8OCRXsgka2a', 'Toffano', 'Talmadge', 'Alley'),
('c0005', 'mmarlow4@dedecms.com', '24 Schurz Junction', '55312001', 'Mei', '7tgGqd', 'Marlow', 'Schurz', 'Junction'),
('c0007', 'tes12t@example.com', '123 Main St', '55923234', 'John', 'password', 'Doe', 'Main St', 'Anytown'),
('c0008', 'tes112t@example.com', '123 Main St', '51923234', 'John', 'password', 'Doe', 'Main St', 'Anytown'),
('c0009', 'tes1112t@example.com', '123 Main St', '51923231', 'John', 'password', 'Doe', 'Main St', 'Anytown'),
('c0010', 'jane_doe@example.com', '1234 Elm St', '1234567891', 'Jane', 'pswd1234', 'Doe', 'Elm', 'St'),
('c0011', 'john_smith@example.com', '5678 Oak Ave', '0987654321', 'John', 'abc@1234', 'Smith', 'Oak', 'Ave'),
('c0012', 'amy_johnson@example.com', '9876 Maple St', '2345678901', 'Amy', 'myp@ssword', 'Johnson', 'Maple', 'St'),
('c0013', 'david_lee@example.com', '2468 Pine Rd', '7654321098', 'David', 'qwerty123', 'Lee', 'Pine', 'Rd'),
('c0014', 'sarah_green@example.com', '3690 Birch Ln', '0123456789', 'Sarah', 'p@ssword', 'Green', 'Birch', 'Ln');

-- --------------------------------------------------------

--
-- Stand-in structure for view `customer_purchase_summary`
-- (See below for the actual view)
--
CREATE TABLE `customer_purchase_summary` (
`customerId` varchar(5)
,`custFName` varchar(20)
,`custLName` varchar(20)
,`total_purchase_price` double
);

-- --------------------------------------------------------

--
-- Table structure for table `emailsend`
--

CREATE TABLE `emailsend` (
  `pCustId` varchar(5) NOT NULL,
  `bulkEmailId` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `emailsend`
--

INSERT INTO `emailsend` (`pCustId`, `bulkEmailId`) VALUES
('pc001', 'bu001'),
('pc002', 'bu001'),
('pc003', 'bu001'),
('pc004', 'bu004'),
('pc005', 'bu005');

-- --------------------------------------------------------

--
-- Table structure for table `potentialcustomer`
--

CREATE TABLE `potentialcustomer` (
  `pCustId` varchar(5) NOT NULL,
  `pCustName` varchar(50) NOT NULL,
  `pCustEmail` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `potentialcustomer`
--

INSERT INTO `potentialcustomer` (`pCustId`, `pCustName`, `pCustEmail`) VALUES
('pc001', 'Eben Quenby', 'equenby0@nytimes.com'),
('pc002', 'Ilysa Lidgey', 'ilidgey1@tuttocitta.it'),
('pc003', 'Ophelie Garwill', 'ogarwill2@slashdot.org'),
('pc004', 'Gar Mowbury', 'gmowbury3@mashable.com'),
('pc005', 'Trevar Mackrill', 'tmackrill4@clickbank.net');

-- --------------------------------------------------------

--
-- Stand-in structure for view `potential_customer_react`
-- (See below for the actual view)
--
CREATE TABLE `potential_customer_react` (
`pCustId` varchar(5)
,`pCustName` varchar(50)
,`num_bulk_emails` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `product`
--

CREATE TABLE `product` (
  `productId` varchar(5) NOT NULL,
  `productName` varchar(20) NOT NULL,
  `productDesc` varchar(100) NOT NULL,
  `productPrice` float NOT NULL,
  `productImage` varchar(100) NOT NULL,
  `productStock` int(11) NOT NULL,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  `sellerId` varchar(5) NOT NULL,
  `productCatId` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `product`
--

INSERT INTO `product` (`productId`, `productName`, `productDesc`, `productPrice`, `productImage`, `productStock`, `date`, `sellerId`, `productCatId`) VALUES
('p0001', 'Apple', 'Apple Mobile for Kids', 1000, 'Image', 25, '2022-01-01 00:00:00', 's0001', 'pc001'),
('p0002', 'Samsung Tv', 'Samsung TV for Adult', 2000, 'Image', 10, '2022-01-05 00:00:00', 's0002', 'pc002'),
('p0003', 'Mac Book', 'Laptop for Mac', 1200, 'Image', 8, '2022-01-09 00:00:00', 's0003', 'pc003'),
('p0004', 'Electric Plug', 'Electic plug for Men', 50, 'Image', 12, '2022-01-10 00:00:00', 's0004', 'pc004'),
('p0005', 'Purse', 'Purse for Men', 80, 'Image', 10, '2022-01-11 00:00:00', 's0005', 'pc005'),
('p0006', 'Product 1', 'This is product 1', 10.99, 'product1.jpg', 100, '2023-03-06 00:00:00', 's0001', 'pc005'),
('p0007', 'Product 7', 'This is product 7', 17.99, 'new_product_image.jpg', 100, '2023-03-06 02:12:34', 's0001', 'pc004');

--
-- Triggers `product`
--
DELIMITER $$
CREATE TRIGGER `check_stock` BEFORE UPDATE ON `product` FOR EACH ROW BEGIN
    IF NEW.productStock < 0 THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Product stock cannot be less than 0';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `productcateogary`
--

CREATE TABLE `productcateogary` (
  `productCatId` varchar(5) NOT NULL,
  `productCateogary` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `productcateogary`
--

INSERT INTO `productcateogary` (`productCatId`, `productCateogary`) VALUES
('pc001', 'Mobile'),
('pc002', 'Television'),
('pc003', 'Laptop'),
('pc004', 'Electic Items'),
('pc005', 'Wearables');

-- --------------------------------------------------------

--
-- Stand-in structure for view `product_info`
-- (See below for the actual view)
--
CREATE TABLE `product_info` (
`productName` varchar(20)
,`productDesc` varchar(100)
,`productPrice` float
,`productImage` varchar(100)
,`productStock` int(11)
,`businessRegNumber` varchar(15)
,`sellerFName` varchar(20)
,`sellerLName` varchar(20)
,`productCateogary` varchar(20)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `product_sales_quantities`
-- (See below for the actual view)
--
CREATE TABLE `product_sales_quantities` (
`productId` varchar(5)
,`productName` varchar(20)
,`sellerFName` varchar(20)
,`sellerLName` varchar(20)
,`total_quantity` decimal(32,0)
,`total_sales_price` double
);

-- --------------------------------------------------------

--
-- Table structure for table `seller`
--

CREATE TABLE `seller` (
  `sellerId` varchar(5) NOT NULL,
  `idCardNumber` varchar(10) NOT NULL,
  `businessRegNumber` varchar(15) NOT NULL,
  `sellerEmail` varchar(30) NOT NULL,
  `sellerFName` varchar(20) NOT NULL,
  `password` varchar(256) NOT NULL,
  `sellerLName` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `seller`
--

INSERT INTO `seller` (`sellerId`, `idCardNumber`, `businessRegNumber`, `sellerEmail`, `sellerFName`, `password`, `sellerLName`) VALUES
('s0001', '1234567890', 'ABC123456789012', 'sbru12cker2@qq.com', 'John', '89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8', 'Doe'),
('s0002', 'ce178738-e', '54314149', 'khelin1@usa.gov', 'Kenny', '89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8', 'Helin'),
('s0003', 'bf7568d4-2', '14312624013', 'sbrucker2@qq.com', 'Sheila-kathryn', '89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8', 'Brucker'),
('s0004', '26f4e724-8', '83864831', 'nraccio3@google.cn', 'Nathanael', '89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8', 'Raccio'),
('s0005', '83554b08-d', '1433137119', 'mpavolillo4@go.com', 'Maynard', '89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8', 'Pavolillo'),
('s0006', '1234567890', 'ABC123456789012', 'john@example.com', 'John', '89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8', 'Doe'),
('s0007', '1234167890', 'ABC173456789012', 'john@example1.com', 'John', '89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8', 'Doe');

-- --------------------------------------------------------

--
-- Table structure for table `sellermanage`
--

CREATE TABLE `sellermanage` (
  `sellerManageId` varchar(5) NOT NULL,
  `action` varchar(10) NOT NULL,
  `adminId` varchar(5) NOT NULL,
  `sellerId` varchar(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sellermanage`
--

INSERT INTO `sellermanage` (`sellerManageId`, `action`, `adminId`, `sellerId`) VALUES
('sm001', 'activated', 'a001', 's0001'),
('sm002', 'activated', 'a002', 's0002'),
('sm003', 'activated', 'a003', 's0003'),
('sm004', 'activated', 'a004', 's0004'),
('sm005', 'activated', 'a005', 's0005');

-- --------------------------------------------------------

--
-- Stand-in structure for view `seller_sales`
-- (See below for the actual view)
--
CREATE TABLE `seller_sales` (
`sellerId` varchar(5)
,`sellerFName` varchar(20)
,`sellerLName` varchar(20)
,`total_sales` double
);

-- --------------------------------------------------------

--
-- Structure for view `customer_purchase_summary`
--
DROP TABLE IF EXISTS `customer_purchase_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`user`@`localhost` SQL SECURITY DEFINER VIEW `customer_purchase_summary`  AS SELECT `o`.`customerId` AS `customerId`, `cust`.`custFName` AS `custFName`, `cust`.`custLName` AS `custLName`, sum(`c`.`quantity` * `p`.`productPrice`) AS `total_purchase_price` FROM (((`product` `p` join `cart` `c` on(`p`.`productId` = `c`.`productId`)) join `corder` `o` on(`c`.`orderId` = `o`.`orderId`)) join `customer` `cust` on(`o`.`customerId` = `cust`.`customerId`)) WHERE `o`.`orderStatus` = 0 GROUP BY `o`.`customerId`, `cust`.`custFName`, `cust`.`custLName``custLName`  ;

-- --------------------------------------------------------

--
-- Structure for view `potential_customer_react`
--
DROP TABLE IF EXISTS `potential_customer_react`;

CREATE ALGORITHM=UNDEFINED DEFINER=`user`@`localhost` SQL SECURITY DEFINER VIEW `potential_customer_react`  AS SELECT `pc`.`pCustId` AS `pCustId`, `pc`.`pCustName` AS `pCustName`, count(`es`.`bulkEmailId`) AS `num_bulk_emails` FROM ((`potentialcustomer` `pc` left join `emailsend` `es` on(`pc`.`pCustId` = `es`.`pCustId`)) left join `bulkemail` `be` on(`es`.`bulkEmailId` = `be`.`bulkEmailId`)) WHERE `be`.`bulkstatus` = 0 GROUP BY `pc`.`pCustId`, `pc`.`pCustName``pCustName`  ;

-- --------------------------------------------------------

--
-- Structure for view `product_info`
--
DROP TABLE IF EXISTS `product_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=`user`@`localhost` SQL SECURITY DEFINER VIEW `product_info`  AS SELECT `p`.`productName` AS `productName`, `p`.`productDesc` AS `productDesc`, `p`.`productPrice` AS `productPrice`, `p`.`productImage` AS `productImage`, `p`.`productStock` AS `productStock`, `s`.`businessRegNumber` AS `businessRegNumber`, `s`.`sellerFName` AS `sellerFName`, `s`.`sellerLName` AS `sellerLName`, `pc`.`productCateogary` AS `productCateogary` FROM ((`product` `p` join `seller` `s` on(`p`.`sellerId` = `s`.`sellerId`)) join `productcateogary` `pc` on(`p`.`productCatId` = `pc`.`productCatId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `product_sales_quantities`
--
DROP TABLE IF EXISTS `product_sales_quantities`;

CREATE ALGORITHM=UNDEFINED DEFINER=`user`@`localhost` SQL SECURITY DEFINER VIEW `product_sales_quantities`  AS SELECT `p`.`productId` AS `productId`, `p`.`productName` AS `productName`, `s`.`sellerFName` AS `sellerFName`, `s`.`sellerLName` AS `sellerLName`, sum(`c`.`quantity`) AS `total_quantity`, sum(`c`.`quantity` * `p`.`productPrice`) AS `total_sales_price` FROM (((`product` `p` join `cart` `c` on(`p`.`productId` = `c`.`productId`)) join `corder` `o` on(`c`.`orderId` = `o`.`orderId`)) join `seller` `s` on(`p`.`sellerId` = `s`.`sellerId`)) WHERE `o`.`orderStatus` = 0 GROUP BY `p`.`productId`, `p`.`productName`, `s`.`sellerFName`, `s`.`sellerLName``sellerLName`  ;

-- --------------------------------------------------------

--
-- Structure for view `seller_sales`
--
DROP TABLE IF EXISTS `seller_sales`;

CREATE ALGORITHM=UNDEFINED DEFINER=`user`@`localhost` SQL SECURITY DEFINER VIEW `seller_sales`  AS SELECT `p`.`sellerId` AS `sellerId`, `s`.`sellerFName` AS `sellerFName`, `s`.`sellerLName` AS `sellerLName`, sum(`c`.`quantity` * `p`.`productPrice`) AS `total_sales` FROM (((`product` `p` join `cart` `c` on(`p`.`productId` = `c`.`productId`)) join `corder` `o` on(`c`.`orderId` = `o`.`orderId`)) join `seller` `s` on(`p`.`sellerId` = `s`.`sellerId`)) WHERE `o`.`orderStatus` = 0 GROUP BY `p`.`sellerId`, `s`.`sellerFName`, `s`.`sellerLName``sellerLName`  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `badmin`
--
ALTER TABLE `badmin`
  ADD PRIMARY KEY (`adminId`);

--
-- Indexes for table `bulkemail`
--
ALTER TABLE `bulkemail`
  ADD PRIMARY KEY (`bulkEmailId`),
  ADD KEY `adminId` (`adminId`);

--
-- Indexes for table `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`productId`,`orderId`),
  ADD KEY `orderId` (`orderId`);

--
-- Indexes for table `corder`
--
ALTER TABLE `corder`
  ADD PRIMARY KEY (`orderId`),
  ADD KEY `customerId` (`customerId`);

--
-- Indexes for table `custmanage`
--
ALTER TABLE `custmanage`
  ADD PRIMARY KEY (`custmanageId`),
  ADD KEY `adminId` (`adminId`),
  ADD KEY `customerId` (`customerId`);

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`customerId`),
  ADD KEY `cust_f_name_idx` (`custFName`),
  ADD KEY `cust_l_name_idx` (`custLName`),
  ADD KEY `cust_city_idx` (`custCity`);

--
-- Indexes for table `emailsend`
--
ALTER TABLE `emailsend`
  ADD PRIMARY KEY (`pCustId`,`bulkEmailId`),
  ADD KEY `bulkEmailId` (`bulkEmailId`);

--
-- Indexes for table `potentialcustomer`
--
ALTER TABLE `potentialcustomer`
  ADD PRIMARY KEY (`pCustId`);

--
-- Indexes for table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`productId`),
  ADD KEY `sellerId` (`sellerId`),
  ADD KEY `productCatId` (`productCatId`);

--
-- Indexes for table `productcateogary`
--
ALTER TABLE `productcateogary`
  ADD PRIMARY KEY (`productCatId`);

--
-- Indexes for table `seller`
--
ALTER TABLE `seller`
  ADD PRIMARY KEY (`sellerId`);

--
-- Indexes for table `sellermanage`
--
ALTER TABLE `sellermanage`
  ADD PRIMARY KEY (`sellerManageId`),
  ADD KEY `adminId` (`adminId`),
  ADD KEY `sellerId` (`sellerId`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bulkemail`
--
ALTER TABLE `bulkemail`
  ADD CONSTRAINT `bulkemail_ibfk_1` FOREIGN KEY (`adminId`) REFERENCES `badmin` (`adminId`);

--
-- Constraints for table `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`productId`) REFERENCES `product` (`productId`),
  ADD CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`orderId`) REFERENCES `corder` (`orderId`);

--
-- Constraints for table `corder`
--
ALTER TABLE `corder`
  ADD CONSTRAINT `corder_ibfk_1` FOREIGN KEY (`customerId`) REFERENCES `customer` (`customerId`);

--
-- Constraints for table `custmanage`
--
ALTER TABLE `custmanage`
  ADD CONSTRAINT `custmanage_ibfk_1` FOREIGN KEY (`adminId`) REFERENCES `badmin` (`adminId`),
  ADD CONSTRAINT `custmanage_ibfk_2` FOREIGN KEY (`customerId`) REFERENCES `customer` (`customerId`);

--
-- Constraints for table `emailsend`
--
ALTER TABLE `emailsend`
  ADD CONSTRAINT `emailsend_ibfk_1` FOREIGN KEY (`pCustId`) REFERENCES `potentialcustomer` (`pCustId`),
  ADD CONSTRAINT `emailsend_ibfk_2` FOREIGN KEY (`bulkEmailId`) REFERENCES `bulkemail` (`bulkEmailId`);

--
-- Constraints for table `product`
--
ALTER TABLE `product`
  ADD CONSTRAINT `product_ibfk_1` FOREIGN KEY (`sellerId`) REFERENCES `seller` (`sellerId`),
  ADD CONSTRAINT `product_ibfk_2` FOREIGN KEY (`productCatId`) REFERENCES `productcateogary` (`productCatId`);

--
-- Constraints for table `sellermanage`
--
ALTER TABLE `sellermanage`
  ADD CONSTRAINT `sellermanage_ibfk_1` FOREIGN KEY (`adminId`) REFERENCES `badmin` (`adminId`),
  ADD CONSTRAINT `sellermanage_ibfk_2` FOREIGN KEY (`sellerId`) REFERENCES `seller` (`sellerId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
