-- MySQL dump 10.13  Distrib 8.0.18, for osx10.15 (x86_64)
--
-- Host: localhost    Database: seek_pub_development
-- ------------------------------------------------------
-- Server version	8.0.18

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `publication_types`
--

DROP TABLE IF EXISTS `publication_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publication_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `key` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publication_types`
--

LOCK TABLES `publication_types` WRITE;
/*!40000 ALTER TABLE `publication_types` DISABLE KEYS */;
INSERT INTO `publication_types` VALUES (1,'Journal','article','2019-09-03 12:32:52','2019-09-03 12:32:52'),(2,'Book','book','2019-09-03 12:32:52','2019-09-03 12:32:52'),(3,'Booklet','booklet','2019-09-03 12:32:52','2019-09-03 12:32:52'),(4,'InBook','inbook','2019-09-03 12:32:52','2019-09-03 12:32:52'),(5,'InCollection','incollection','2019-09-03 12:32:52','2019-09-03 12:32:52'),(6,'InProceedings','inproceedings','2019-09-03 12:32:52','2019-09-03 12:32:52'),(7,'Manual','manual','2019-09-03 12:32:52','2019-09-03 12:32:52'),(8,'Masters Thesis','mastersthesis','2019-09-03 12:32:52','2019-09-03 12:32:52'),(9,'Misc','misc','2019-09-03 12:32:52','2019-09-03 12:32:52'),(10,'Phd Thesis','phdthesis','2019-09-03 12:32:52','2019-09-03 12:32:52'),(11,'Proceedings','proceedings','2019-09-03 12:32:52','2019-09-03 12:32:52'),(12,'Tech report','techreport','2019-09-03 12:32:52','2019-09-03 12:32:52'),(13,'Unpublished','unpublished','2019-09-03 12:32:52','2019-09-03 12:32:52');
/*!40000 ALTER TABLE `publication_types` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-01-10 12:54:58
