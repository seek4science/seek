-- MySQL dump 10.13  Distrib 8.0.18, for osx10.15 (x86_64)
--
-- Host: localhost    Database: seek_pub_production
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
-- Table structure for table `activity_logs`
--

DROP TABLE IF EXISTS `activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action` varchar(255) DEFAULT NULL,
  `format` varchar(255) DEFAULT NULL,
  `activity_loggable_type` varchar(255) DEFAULT NULL,
  `activity_loggable_id` int(11) DEFAULT NULL,
  `culprit_type` varchar(255) DEFAULT NULL,
  `culprit_id` int(11) DEFAULT NULL,
  `referenced_type` varchar(255) DEFAULT NULL,
  `referenced_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `http_referer` varchar(255) DEFAULT NULL,
  `user_agent` text,
  `data` mediumtext,
  `controller_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `act_logs_action_index` (`action`),
  KEY `act_logs_act_loggable_index` (`activity_loggable_type`,`activity_loggable_id`),
  KEY `act_logs_culprit_index` (`culprit_type`,`culprit_id`),
  KEY `act_logs_format_index` (`format`),
  KEY `act_logs_referenced_index` (`referenced_type`,`referenced_id`)
) ENGINE=InnoDB AUTO_INCREMENT=321 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_logs`
--

LOCK TABLES `activity_logs` WRITE;
/*!40000 ALTER TABLE `activity_logs` DISABLE KEYS */;
INSERT INTO `activity_logs` VALUES (1,'show',NULL,'Project',3,NULL,NULL,NULL,NULL,'2019-09-03 12:36:26','2019-09-03 12:36:26',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(2,'update',NULL,'Project',3,'User',1,NULL,NULL,'2019-09-03 12:36:26','2019-09-03 12:36:26',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(3,'show',NULL,'Project',4,NULL,NULL,NULL,NULL,'2019-09-03 12:36:26','2019-09-03 12:36:26',NULL,'python-requests/2.22.0','--- Computational Carbon Chemistry\n','projects'),(4,'update',NULL,'Project',4,'User',1,NULL,NULL,'2019-09-03 12:36:26','2019-09-03 12:36:26',NULL,'python-requests/2.22.0','--- Computational Carbon Chemistry\n','projects'),(5,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(6,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(7,'show',NULL,'Project',6,NULL,NULL,NULL,NULL,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(8,'update',NULL,'Project',6,'User',1,NULL,NULL,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(9,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(10,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:36:28','2019-09-03 12:36:28',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(11,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:36:28','2019-09-03 12:36:28',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(12,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:36:28','2019-09-03 12:36:28',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(13,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:36:28','2019-09-03 12:36:28',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(14,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:36:28','2019-09-03 12:36:28',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(15,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(16,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(17,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(18,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(19,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(20,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:36:30','2019-09-03 12:36:30',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(21,'create',NULL,'Person',2,'User',1,NULL,NULL,'2019-09-03 12:37:39','2019-09-03 12:37:39',NULL,'python-requests/2.22.0','--- Antonio Disanto\n','people'),(22,'show',NULL,'Project',3,NULL,NULL,NULL,NULL,'2019-09-03 12:37:39','2019-09-03 12:37:39',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(23,'update',NULL,'Project',3,'User',1,NULL,NULL,'2019-09-03 12:37:39','2019-09-03 12:37:39',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(24,'create',NULL,'Person',3,'User',1,NULL,NULL,'2019-09-03 12:37:39','2019-09-03 12:37:39',NULL,'python-requests/2.22.0','--- Nikos Gianniotis\n','people'),(25,'show',NULL,'Project',3,NULL,NULL,NULL,NULL,'2019-09-03 12:37:40','2019-09-03 12:37:40',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(26,'update',NULL,'Project',3,'User',1,NULL,NULL,'2019-09-03 12:37:40','2019-09-03 12:37:40',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(27,'create',NULL,'Person',4,'User',1,NULL,NULL,'2019-09-03 12:37:40','2019-09-03 12:37:40',NULL,'python-requests/2.22.0','--- Erica Hopkins\n','people'),(28,'show',NULL,'Project',3,NULL,NULL,NULL,NULL,'2019-09-03 12:37:41','2019-09-03 12:37:41',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(29,'update',NULL,'Project',3,'User',1,NULL,NULL,'2019-09-03 12:37:41','2019-09-03 12:37:41',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(30,'create',NULL,'Person',5,'User',1,NULL,NULL,'2019-09-03 12:37:41','2019-09-03 12:37:41',NULL,'python-requests/2.22.0','--- Fenja Kollasch\n','people'),(31,'show',NULL,'Project',3,NULL,NULL,NULL,NULL,'2019-09-03 12:37:41','2019-09-03 12:37:41',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(32,'update',NULL,'Project',3,'User',1,NULL,NULL,'2019-09-03 12:37:42','2019-09-03 12:37:42',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(33,'create',NULL,'Person',6,'User',1,NULL,NULL,'2019-09-03 12:37:42','2019-09-03 12:37:42',NULL,'python-requests/2.22.0','--- Markus Nullmeier\n','people'),(34,'show',NULL,'Project',3,NULL,NULL,NULL,NULL,'2019-09-03 12:37:42','2019-09-03 12:37:42',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(35,'update',NULL,'Project',3,'User',1,NULL,NULL,'2019-09-03 12:37:43','2019-09-03 12:37:43',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(36,'create',NULL,'Person',7,'User',1,NULL,NULL,'2019-09-03 12:37:43','2019-09-03 12:37:43',NULL,'python-requests/2.22.0','--- Kai Polsterer\n','people'),(37,'show',NULL,'Project',3,NULL,NULL,NULL,NULL,'2019-09-03 12:37:43','2019-09-03 12:37:43',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(38,'update',NULL,'Project',3,'User',1,NULL,NULL,'2019-09-03 12:37:44','2019-09-03 12:37:44',NULL,'python-requests/2.22.0','--- Astroinformatics\n','projects'),(39,'create',NULL,'Person',8,'User',1,NULL,NULL,'2019-09-03 12:37:44','2019-09-03 12:37:44',NULL,'python-requests/2.22.0','--- Ganna Gryn\'Ova\n','people'),(40,'show',NULL,'Project',4,NULL,NULL,NULL,NULL,'2019-09-03 12:37:44','2019-09-03 12:37:44',NULL,'python-requests/2.22.0','--- Computational Carbon Chemistry\n','projects'),(41,'update',NULL,'Project',4,'User',1,NULL,NULL,'2019-09-03 12:37:45','2019-09-03 12:37:45',NULL,'python-requests/2.22.0','--- Computational Carbon Chemistry\n','projects'),(42,'create',NULL,'Person',9,'User',1,NULL,NULL,'2019-09-03 12:37:45','2019-09-03 12:37:45',NULL,'python-requests/2.22.0','--- Pierre Barbera\n','people'),(43,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:45','2019-09-03 12:37:45',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(44,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:45','2019-09-03 12:37:45',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(45,'create',NULL,'Person',10,'User',1,NULL,NULL,'2019-09-03 12:37:46','2019-09-03 12:37:46',NULL,'python-requests/2.22.0','--- Ben Bettisworth\n','people'),(46,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:46','2019-09-03 12:37:46',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(47,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:46','2019-09-03 12:37:46',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(48,'create',NULL,'Person',11,'User',1,NULL,NULL,'2019-09-03 12:37:46','2019-09-03 12:37:46',NULL,'python-requests/2.22.0','--- Alexey Kozlov\n','people'),(49,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:47','2019-09-03 12:37:47',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(50,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:47','2019-09-03 12:37:47',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(51,'create',NULL,'Person',12,'User',1,NULL,NULL,'2019-09-03 12:37:47','2019-09-03 12:37:47',NULL,'python-requests/2.22.0','--- Sarah Lutteropp\n','people'),(52,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:47','2019-09-03 12:37:47',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(53,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:48','2019-09-03 12:37:48',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(54,'create',NULL,'Person',13,'User',1,NULL,NULL,'2019-09-03 12:37:48','2019-09-03 12:37:48',NULL,'python-requests/2.22.0','--- Benoit Morel\n','people'),(55,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:48','2019-09-03 12:37:48',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(56,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:49','2019-09-03 12:37:49',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(57,'create',NULL,'Person',14,'User',1,NULL,NULL,'2019-09-03 12:37:49','2019-09-03 12:37:49',NULL,'python-requests/2.22.0','--- Alexandros Stamatakis\n','people'),(58,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:49','2019-09-03 12:37:49',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(59,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:50','2019-09-03 12:37:50',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(60,'create',NULL,'Person',15,'User',1,NULL,NULL,'2019-09-03 12:37:50','2019-09-03 12:37:50',NULL,'python-requests/2.22.0','--- Johanna Wegmann\n','people'),(61,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:50','2019-09-03 12:37:50',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(62,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:51','2019-09-03 12:37:51',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(63,'create',NULL,'Person',16,'User',1,NULL,NULL,'2019-09-03 12:37:51','2019-09-03 12:37:51',NULL,'python-requests/2.22.0','--- Adrian Zapletal\n','people'),(64,'show',NULL,'Project',5,NULL,NULL,NULL,NULL,'2019-09-03 12:37:52','2019-09-03 12:37:52',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(65,'update',NULL,'Project',5,'User',1,NULL,NULL,'2019-09-03 12:37:52','2019-09-03 12:37:52',NULL,'python-requests/2.22.0','--- Computational Molecular Evolution\n','projects'),(66,'create',NULL,'Person',17,'User',1,NULL,NULL,'2019-09-03 12:37:52','2019-09-03 12:37:52',NULL,'python-requests/2.22.0','--- Timo Dimitriadis\n','people'),(67,'show',NULL,'Project',6,NULL,NULL,NULL,NULL,'2019-09-03 12:37:53','2019-09-03 12:37:53',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(68,'update',NULL,'Project',6,'User',1,NULL,NULL,'2019-09-03 12:37:53','2019-09-03 12:37:53',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(69,'create',NULL,'Person',18,'User',1,NULL,NULL,'2019-09-03 12:37:53','2019-09-03 12:37:53',NULL,'python-requests/2.22.0','--- Tilmann Gneiting\n','people'),(70,'show',NULL,'Project',6,NULL,NULL,NULL,NULL,'2019-09-03 12:37:53','2019-09-03 12:37:53',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(71,'update',NULL,'Project',6,'User',1,NULL,NULL,'2019-09-03 12:37:54','2019-09-03 12:37:54',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(72,'create',NULL,'Person',19,'User',1,NULL,NULL,'2019-09-03 12:37:54','2019-09-03 12:37:54',NULL,'python-requests/2.22.0','--- Sebastian Lerch\n','people'),(73,'show',NULL,'Project',6,NULL,NULL,NULL,NULL,'2019-09-03 12:37:54','2019-09-03 12:37:54',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(74,'update',NULL,'Project',6,'User',1,NULL,NULL,'2019-09-03 12:37:55','2019-09-03 12:37:55',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(75,'create',NULL,'Person',20,'User',1,NULL,NULL,'2019-09-03 12:37:55','2019-09-03 12:37:55',NULL,'python-requests/2.22.0','--- Johannes Resin\n','people'),(76,'show',NULL,'Project',6,NULL,NULL,NULL,NULL,'2019-09-03 12:37:55','2019-09-03 12:37:55',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(77,'update',NULL,'Project',6,'User',1,NULL,NULL,'2019-09-03 12:37:55','2019-09-03 12:37:55',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(78,'create',NULL,'Person',21,'User',1,NULL,NULL,'2019-09-03 12:37:56','2019-09-03 12:37:56',NULL,'python-requests/2.22.0','--- Patrick Schmidt\n','people'),(79,'show',NULL,'Project',6,NULL,NULL,NULL,NULL,'2019-09-03 12:37:56','2019-09-03 12:37:56',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(80,'update',NULL,'Project',6,'User',1,NULL,NULL,'2019-09-03 12:37:57','2019-09-03 12:37:57',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(81,'create',NULL,'Person',22,'User',1,NULL,NULL,'2019-09-03 12:37:57','2019-09-03 12:37:57',NULL,'python-requests/2.22.0','--- Eva-Maria Walz\n','people'),(82,'show',NULL,'Project',6,NULL,NULL,NULL,NULL,'2019-09-03 12:37:57','2019-09-03 12:37:57',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(83,'update',NULL,'Project',6,'User',1,NULL,NULL,'2019-09-03 12:37:58','2019-09-03 12:37:58',NULL,'python-requests/2.22.0','--- Computational Statistics\n','projects'),(84,'create',NULL,'Person',23,'User',1,NULL,NULL,'2019-09-03 12:37:58','2019-09-03 12:37:58',NULL,'python-requests/2.22.0','--- Charlotte Boys\n','people'),(85,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:37:58','2019-09-03 12:37:58',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(86,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:37:58','2019-09-03 12:37:58',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(87,'create',NULL,'Person',24,'User',1,NULL,NULL,'2019-09-03 12:37:58','2019-09-03 12:37:58',NULL,'python-requests/2.22.0','--- Philipp Gerstner\n','people'),(88,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:37:59','2019-09-03 12:37:59',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(89,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:37:59','2019-09-03 12:37:59',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(90,'create',NULL,'Person',25,'User',1,NULL,NULL,'2019-09-03 12:37:59','2019-09-03 12:37:59',NULL,'python-requests/2.22.0','--- Vincent Heuveline\n','people'),(91,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:38:00','2019-09-03 12:38:00',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(92,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:38:00','2019-09-03 12:38:00',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(93,'create',NULL,'Person',26,'User',1,NULL,NULL,'2019-09-03 12:38:00','2019-09-03 12:38:00',NULL,'python-requests/2.22.0','--- Maximilian Hoecker\n','people'),(94,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:38:00','2019-09-03 12:38:00',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(95,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:38:01','2019-09-03 12:38:01',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(96,'create',NULL,'Person',27,'User',1,NULL,NULL,'2019-09-03 12:38:01','2019-09-03 12:38:01',NULL,'python-requests/2.22.0','--- Alejandra Jayme\n','people'),(97,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:38:01','2019-09-03 12:38:01',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(98,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:38:02','2019-09-03 12:38:02',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(99,'create',NULL,'Person',28,'User',1,NULL,NULL,'2019-09-03 12:38:02','2019-09-03 12:38:02',NULL,'python-requests/2.22.0','--- Sotirios Nikas\n','people'),(100,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:38:02','2019-09-03 12:38:02',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(101,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:38:03','2019-09-03 12:38:03',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(102,'create',NULL,'Person',29,'User',1,NULL,NULL,'2019-09-03 12:38:03','2019-09-03 12:38:03',NULL,'python-requests/2.22.0','--- Jonas Roller\n','people'),(103,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:38:03','2019-09-03 12:38:03',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(104,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:38:04','2019-09-03 12:38:04',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(105,'create',NULL,'Person',30,'User',1,NULL,NULL,'2019-09-03 12:38:04','2019-09-03 12:38:04',NULL,'python-requests/2.22.0','--- Chen Song\n','people'),(106,'show',NULL,'Project',7,NULL,NULL,NULL,NULL,'2019-09-03 12:38:05','2019-09-03 12:38:05',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(107,'update',NULL,'Project',7,'User',1,NULL,NULL,'2019-09-03 12:38:05','2019-09-03 12:38:05',NULL,'python-requests/2.22.0','--- Data Mining and Uncertainty Quantification\n','projects'),(108,'create',NULL,'Person',31,'User',1,NULL,NULL,'2019-09-03 12:38:06','2019-09-03 12:38:06',NULL,'python-requests/2.22.0','--- Jonas Beyrer\n','people'),(109,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:38:06','2019-09-03 12:38:06',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(110,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:38:06','2019-09-03 12:38:06',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(111,'create',NULL,'Person',32,'User',1,NULL,NULL,'2019-09-03 12:38:06','2019-09-03 12:38:06',NULL,'python-requests/2.22.0','--- Clemens Fruböse\n','people'),(112,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:38:07','2019-09-03 12:38:07',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(113,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:38:07','2019-09-03 12:38:07',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(114,'create',NULL,'Person',33,'User',1,NULL,NULL,'2019-09-03 12:38:07','2019-09-03 12:38:07',NULL,'python-requests/2.22.0','--- Mareike Pfeil\n','people'),(115,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:38:07','2019-09-03 12:38:07',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(116,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:38:08','2019-09-03 12:38:08',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(117,'create',NULL,'Person',34,'User',1,NULL,NULL,'2019-09-03 12:38:08','2019-09-03 12:38:08',NULL,'python-requests/2.22.0','--- Lukas Sauer\n','people'),(118,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:38:08','2019-09-03 12:38:08',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(119,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:38:09','2019-09-03 12:38:09',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(120,'create',NULL,'Person',35,'User',1,NULL,NULL,'2019-09-03 12:38:09','2019-09-03 12:38:09',NULL,'python-requests/2.22.0','--- Florian Stecker\n','people'),(121,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:38:09','2019-09-03 12:38:09',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(122,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:38:10','2019-09-03 12:38:10',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(123,'create',NULL,'Person',36,'User',1,NULL,NULL,'2019-09-03 12:38:10','2019-09-03 12:38:10',NULL,'python-requests/2.22.0','--- Anna Wienhard\n','people'),(124,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:38:10','2019-09-03 12:38:10',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(125,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:38:11','2019-09-03 12:38:11',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(126,'create',NULL,'Person',37,'User',1,NULL,NULL,'2019-09-03 12:38:11','2019-09-03 12:38:11',NULL,'python-requests/2.22.0','--- Menelaos Zikidis\n','people'),(127,'show',NULL,'Project',8,NULL,NULL,NULL,NULL,'2019-09-03 12:38:11','2019-09-03 12:38:11',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(128,'update',NULL,'Project',8,'User',1,NULL,NULL,'2019-09-03 12:38:12','2019-09-03 12:38:12',NULL,'python-requests/2.22.0','--- Groups and Geometry\n','projects'),(129,'create',NULL,'Person',38,'User',1,NULL,NULL,'2019-09-03 12:38:12','2019-09-03 12:38:12',NULL,'python-requests/2.22.0','--- Csaba Daday\n','people'),(130,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:12','2019-09-03 12:38:12',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(131,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:13','2019-09-03 12:38:13',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(132,'create',NULL,'Person',39,'User',1,NULL,NULL,'2019-09-03 12:38:13','2019-09-03 12:38:13',NULL,'python-requests/2.22.0','--- Svenja De Buhr\n','people'),(133,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:13','2019-09-03 12:38:13',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(134,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:13','2019-09-03 12:38:13',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(135,'create',NULL,'Person',40,'User',1,NULL,NULL,'2019-09-03 12:38:13','2019-09-03 12:38:13',NULL,'python-requests/2.22.0','--- Krisztina Feher\n','people'),(136,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:14','2019-09-03 12:38:14',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(137,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:14','2019-09-03 12:38:14',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(138,'create',NULL,'Person',41,'User',1,NULL,NULL,'2019-09-03 12:38:14','2019-09-03 12:38:14',NULL,'python-requests/2.22.0','--- Florian Franz\n','people'),(139,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:15','2019-09-03 12:38:15',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(140,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:15','2019-09-03 12:38:15',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(141,'create',NULL,'Person',42,'User',1,NULL,NULL,'2019-09-03 12:38:15','2019-09-03 12:38:15',NULL,'python-requests/2.22.0','--- Frauke Gräter\n','people'),(142,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:16','2019-09-03 12:38:16',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(143,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:16','2019-09-03 12:38:16',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(144,'create',NULL,'Person',43,'User',1,NULL,NULL,'2019-09-03 12:38:16','2019-09-03 12:38:16',NULL,'python-requests/2.22.0','--- Ana Herrera-Rodriguez\n','people'),(145,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:17','2019-09-03 12:38:17',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(146,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:17','2019-09-03 12:38:17',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(147,'create',NULL,'Person',44,'User',1,NULL,NULL,'2019-09-03 12:38:17','2019-09-03 12:38:17',NULL,'python-requests/2.22.0','--- Fan Jin\n','people'),(148,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:18','2019-09-03 12:38:18',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(149,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:18','2019-09-03 12:38:18',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(150,'create',NULL,'Person',45,'User',1,NULL,NULL,'2019-09-03 12:38:18','2019-09-03 12:38:18',NULL,'python-requests/2.22.0','--- Markus Kurth\n','people'),(151,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:19','2019-09-03 12:38:19',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(152,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:19','2019-09-03 12:38:19',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(153,'create',NULL,'Person',46,'User',1,NULL,NULL,'2019-09-03 12:38:20','2019-09-03 12:38:20',NULL,'python-requests/2.22.0','--- Fabian Kutzki\n','people'),(154,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:20','2019-09-03 12:38:20',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(155,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:21','2019-09-03 12:38:21',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(156,'create',NULL,'Person',47,'User',1,NULL,NULL,'2019-09-03 12:38:21','2019-09-03 12:38:21',NULL,'python-requests/2.22.0','--- Isabel Martin\n','people'),(157,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:21','2019-09-03 12:38:21',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(158,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:22','2019-09-03 12:38:22',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(159,'create',NULL,'Person',48,'User',1,NULL,NULL,'2019-09-03 12:38:22','2019-09-03 12:38:22',NULL,'python-requests/2.22.0','--- Nicholas Michelarakis\n','people'),(160,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:23','2019-09-03 12:38:23',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(161,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:23','2019-09-03 12:38:23',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(162,'create',NULL,'Person',49,'User',1,NULL,NULL,'2019-09-03 12:38:24','2019-09-03 12:38:24',NULL,'python-requests/2.22.0','--- Agnieszka Obarska-Kosinska\n','people'),(163,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:24','2019-09-03 12:38:24',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(164,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:25','2019-09-03 12:38:25',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(165,'create',NULL,'Person',50,'User',1,NULL,NULL,'2019-09-03 12:38:25','2019-09-03 12:38:25',NULL,'python-requests/2.22.0','--- Benedikt Rennekamp\n','people'),(166,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:26','2019-09-03 12:38:26',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(167,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:26','2019-09-03 12:38:26',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(168,'create',NULL,'Person',51,'User',1,NULL,NULL,'2019-09-03 12:38:27','2019-09-03 12:38:27',NULL,'python-requests/2.22.0','--- Martin Richter\n','people'),(169,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:27','2019-09-03 12:38:27',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(170,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:28','2019-09-03 12:38:28',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(171,'create',NULL,'Person',52,'User',1,NULL,NULL,'2019-09-03 12:38:29','2019-09-03 12:38:29',NULL,'python-requests/2.22.0','--- Anna Schröder\n','people'),(172,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:29','2019-09-03 12:38:29',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(173,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:30','2019-09-03 12:38:30',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(174,'create',NULL,'Person',53,'User',1,NULL,NULL,'2019-09-03 12:38:30','2019-09-03 12:38:30',NULL,'python-requests/2.22.0','--- Leon Seeger\n','people'),(175,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:31','2019-09-03 12:38:31',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(176,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:32','2019-09-03 12:38:32',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(177,'create',NULL,'Person',54,'User',1,NULL,NULL,'2019-09-03 12:38:32','2019-09-03 12:38:32',NULL,'python-requests/2.22.0','--- Paula Weidemüller\n','people'),(178,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:33','2019-09-03 12:38:33',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(179,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:34','2019-09-03 12:38:34',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(180,'create',NULL,'Person',55,'User',1,NULL,NULL,'2019-09-03 12:38:34','2019-09-03 12:38:34',NULL,'python-requests/2.22.0','--- Christopher Zapp\n','people'),(181,'show',NULL,'Project',9,NULL,NULL,NULL,NULL,'2019-09-03 12:38:35','2019-09-03 12:38:35',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(182,'update',NULL,'Project',9,'User',1,NULL,NULL,'2019-09-03 12:38:36','2019-09-03 12:38:36',NULL,'python-requests/2.22.0','--- Molecular Biomechanics\n','projects'),(183,'create',NULL,'Person',56,'User',1,NULL,NULL,'2019-09-03 12:38:36','2019-09-03 12:38:36',NULL,'python-requests/2.22.0','--- Lukas Adam\n','people'),(184,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:36','2019-09-03 12:38:36',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(185,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:36','2019-09-03 12:38:36',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(186,'create',NULL,'Person',57,'User',1,NULL,NULL,'2019-09-03 12:38:37','2019-09-03 12:38:37',NULL,'python-requests/2.22.0','--- Christina Athanasiou\n','people'),(187,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:37','2019-09-03 12:38:37',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(188,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:37','2019-09-03 12:38:37',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(189,'create',NULL,'Person',58,'User',1,NULL,NULL,'2019-09-03 12:38:37','2019-09-03 12:38:37',NULL,'python-requests/2.22.0','--- Daria Kokh\n','people'),(190,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:38','2019-09-03 12:38:38',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(191,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:38','2019-09-03 12:38:38',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(192,'create',NULL,'Person',59,'User',1,NULL,NULL,'2019-09-03 12:38:38','2019-09-03 12:38:38',NULL,'python-requests/2.22.0','--- Goutam Mukherjee\n','people'),(193,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:39','2019-09-03 12:38:39',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(194,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:39','2019-09-03 12:38:39',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(195,'create',NULL,'Person',60,'User',1,NULL,NULL,'2019-09-03 12:38:39','2019-09-03 12:38:39',NULL,'python-requests/2.22.0','--- Ariane Nunes Alves\n','people'),(196,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:40','2019-09-03 12:38:40',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(197,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:40','2019-09-03 12:38:40',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(198,'create',NULL,'Person',61,'User',1,NULL,NULL,'2019-09-03 12:38:40','2019-09-03 12:38:40',NULL,'python-requests/2.22.0','--- Stefan Richter\n','people'),(199,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:41','2019-09-03 12:38:41',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(200,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:41','2019-09-03 12:38:41',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(201,'create',NULL,'Person',62,'User',1,NULL,NULL,'2019-09-03 12:38:41','2019-09-03 12:38:41',NULL,'python-requests/2.22.0','--- Daniel Saar\n','people'),(202,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:42','2019-09-03 12:38:42',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(203,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:42','2019-09-03 12:38:42',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(204,'create',NULL,'Person',63,'User',1,NULL,NULL,'2019-09-03 12:38:43','2019-09-03 12:38:43',NULL,'python-requests/2.22.0','--- Kashif Sadiq\n','people'),(205,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:43','2019-09-03 12:38:43',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(206,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:44','2019-09-03 12:38:44',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(207,'create',NULL,'Person',64,'User',1,NULL,NULL,'2019-09-03 12:38:44','2019-09-03 12:38:44',NULL,'python-requests/2.22.0','--- Alexandros Tsengenes\n','people'),(208,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:44','2019-09-03 12:38:44',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(209,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:45','2019-09-03 12:38:45',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(210,'create',NULL,'Person',65,'User',1,NULL,NULL,'2019-09-03 12:38:45','2019-09-03 12:38:45',NULL,'python-requests/2.22.0','--- Rebecca Wade\n','people'),(211,'show',NULL,'Project',10,NULL,NULL,NULL,NULL,'2019-09-03 12:38:46','2019-09-03 12:38:46',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(212,'update',NULL,'Project',10,'User',1,NULL,NULL,'2019-09-03 12:38:46','2019-09-03 12:38:46',NULL,'python-requests/2.22.0','--- Molecular and Cellular Modeling\n','projects'),(213,'create',NULL,'Person',66,'User',1,NULL,NULL,'2019-09-03 12:38:47','2019-09-03 12:38:47',NULL,'python-requests/2.22.0','--- Nadia Arslan\n','people'),(214,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:47','2019-09-03 12:38:47',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(215,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:47','2019-09-03 12:38:47',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(216,'create',NULL,'Person',67,'User',1,NULL,NULL,'2019-09-03 12:38:47','2019-09-03 12:38:47',NULL,'python-requests/2.22.0','--- Jason Brockmeyer\n','people'),(217,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:48','2019-09-03 12:38:48',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(218,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:48','2019-09-03 12:38:48',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(219,'create',NULL,'Person',68,'User',1,NULL,NULL,'2019-09-03 12:38:48','2019-09-03 12:38:48',NULL,'python-requests/2.22.0','--- Haixia Chai\n','people'),(220,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:48','2019-09-03 12:38:48',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(221,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:49','2019-09-03 12:38:49',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(222,'create',NULL,'Person',69,'User',1,NULL,NULL,'2019-09-03 12:38:49','2019-09-03 12:38:49',NULL,'python-requests/2.22.0','--- Fabian Düker\n','people'),(223,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:49','2019-09-03 12:38:49',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(224,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:50','2019-09-03 12:38:50',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(225,'create',NULL,'Person',70,'User',1,NULL,NULL,'2019-09-03 12:38:50','2019-09-03 12:38:50',NULL,'python-requests/2.22.0','--- Mehwish Fatima\n','people'),(226,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:50','2019-09-03 12:38:50',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(227,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:51','2019-09-03 12:38:51',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(228,'create',NULL,'Person',71,'User',1,NULL,NULL,'2019-09-03 12:38:51','2019-09-03 12:38:51',NULL,'python-requests/2.22.0','--- Sungho Jeon\n','people'),(229,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:51','2019-09-03 12:38:51',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(230,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:52','2019-09-03 12:38:52',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(231,'create',NULL,'Person',72,'User',1,NULL,NULL,'2019-09-03 12:38:52','2019-09-03 12:38:52',NULL,'python-requests/2.22.0','--- Federico Lopez\n','people'),(232,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:52','2019-09-03 12:38:52',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(233,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:53','2019-09-03 12:38:53',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(234,'create',NULL,'Person',73,'User',1,NULL,NULL,'2019-09-03 12:38:53','2019-09-03 12:38:53',NULL,'python-requests/2.22.0','--- Kevin Mathews\n','people'),(235,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:54','2019-09-03 12:38:54',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(236,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:54','2019-09-03 12:38:54',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(237,'create',NULL,'Person',74,'User',1,NULL,NULL,'2019-09-03 12:38:54','2019-09-03 12:38:54',NULL,'python-requests/2.22.0','--- Mark-Christoph Müller\n','people'),(238,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:55','2019-09-03 12:38:55',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(239,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:56','2019-09-03 12:38:56',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(240,'create',NULL,'Person',75,'User',1,NULL,NULL,'2019-09-03 12:38:56','2019-09-03 12:38:56',NULL,'python-requests/2.22.0','--- Lucas Rettenmeier\n','people'),(241,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:56','2019-09-03 12:38:56',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(242,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:57','2019-09-03 12:38:57',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(243,'create',NULL,'Person',76,'User',1,NULL,NULL,'2019-09-03 12:38:57','2019-09-03 12:38:57',NULL,'python-requests/2.22.0','--- Michael Strube\n','people'),(244,'show',NULL,'Project',11,NULL,NULL,NULL,NULL,'2019-09-03 12:38:58','2019-09-03 12:38:58',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(245,'update',NULL,'Project',11,'User',1,NULL,NULL,'2019-09-03 12:38:58','2019-09-03 12:38:58',NULL,'python-requests/2.22.0','--- Natural Language Processing\n','projects'),(246,'create',NULL,'Person',77,'User',1,NULL,NULL,'2019-09-03 12:38:58','2019-09-03 12:38:58',NULL,'python-requests/2.22.0','--- Robert Andrassy\n','people'),(247,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:38:59','2019-09-03 12:38:59',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(248,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:38:59','2019-09-03 12:38:59',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(249,'create',NULL,'Person',78,'User',1,NULL,NULL,'2019-09-03 12:38:59','2019-09-03 12:38:59',NULL,'python-requests/2.22.0','--- David Bubeck\n','people'),(250,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:00','2019-09-03 12:39:00',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(251,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:00','2019-09-03 12:39:00',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(252,'create',NULL,'Person',79,'User',1,NULL,NULL,'2019-09-03 12:39:00','2019-09-03 12:39:00',NULL,'python-requests/2.22.0','--- Sabrina Gronow\n','people'),(253,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:00','2019-09-03 12:39:00',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(254,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:01','2019-09-03 12:39:01',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(255,'create',NULL,'Person',80,'User',1,NULL,NULL,'2019-09-03 12:39:01','2019-09-03 12:39:01',NULL,'python-requests/2.22.0','--- Leonhard Horst\n','people'),(256,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:01','2019-09-03 12:39:01',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(257,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:02','2019-09-03 12:39:02',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(258,'create',NULL,'Person',81,'User',1,NULL,NULL,'2019-09-03 12:39:02','2019-09-03 12:39:02',NULL,'python-requests/2.22.0','--- Manuel Kramer\n','people'),(259,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:02','2019-09-03 12:39:02',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(260,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:03','2019-09-03 12:39:03',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(261,'create',NULL,'Person',82,'User',1,NULL,NULL,'2019-09-03 12:39:03','2019-09-03 12:39:03',NULL,'python-requests/2.22.0','--- Florian Lach\n','people'),(262,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:03','2019-09-03 12:39:03',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(263,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:04','2019-09-03 12:39:04',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(264,'create',NULL,'Person',83,'User',1,NULL,NULL,'2019-09-03 12:39:04','2019-09-03 12:39:04',NULL,'python-requests/2.22.0','--- Melvin Moreno\n','people'),(265,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:05','2019-09-03 12:39:05',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(266,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:05','2019-09-03 12:39:05',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(267,'create',NULL,'Person',84,'User',1,NULL,NULL,'2019-09-03 12:39:05','2019-09-03 12:39:05',NULL,'python-requests/2.22.0','--- Friedrich Röpke\n','people'),(268,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:06','2019-09-03 12:39:06',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(269,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:06','2019-09-03 12:39:06',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(270,'create',NULL,'Person',85,'User',1,NULL,NULL,'2019-09-03 12:39:07','2019-09-03 12:39:07',NULL,'python-requests/2.22.0','--- Christian Sand\n','people'),(271,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:07','2019-09-03 12:39:07',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(272,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:08','2019-09-03 12:39:08',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(273,'create',NULL,'Person',86,'User',1,NULL,NULL,'2019-09-03 12:39:08','2019-09-03 12:39:08',NULL,'python-requests/2.22.0','--- Fabian Schneider\n','people'),(274,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:08','2019-09-03 12:39:08',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(275,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:09','2019-09-03 12:39:09',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(276,'create',NULL,'Person',87,'User',1,NULL,NULL,'2019-09-03 12:39:09','2019-09-03 12:39:09',NULL,'python-requests/2.22.0','--- Theodoros Soultanis\n','people'),(277,'show',NULL,'Project',12,NULL,NULL,NULL,NULL,'2019-09-03 12:39:10','2019-09-03 12:39:10',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(278,'update',NULL,'Project',12,'User',1,NULL,NULL,'2019-09-03 12:39:10','2019-09-03 12:39:10',NULL,'python-requests/2.22.0','--- Physics of Stellar Objects\n','projects'),(279,'create',NULL,'Person',88,'User',1,NULL,NULL,'2019-09-03 12:39:11','2019-09-03 12:39:11',NULL,'python-requests/2.22.0','--- Sucheta Ghosh\n','people'),(280,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:11','2019-09-03 12:39:11',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(281,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:11','2019-09-03 12:39:11',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(282,'create',NULL,'Person',89,'User',1,NULL,NULL,'2019-09-03 12:39:11','2019-09-03 12:39:11',NULL,'python-requests/2.22.0','--- Martin Golebiewski\n','people'),(283,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:12','2019-09-03 12:39:12',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(284,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:12','2019-09-03 12:39:12',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(285,'create',NULL,'Person',90,'User',1,NULL,NULL,'2019-09-03 12:39:12','2019-09-03 12:39:12',NULL,'python-requests/2.22.0','--- Yachee Gupta\n','people'),(286,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:13','2019-09-03 12:39:13',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(287,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:13','2019-09-03 12:39:13',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(288,'create',NULL,'Person',91,'User',1,NULL,NULL,'2019-09-03 12:39:13','2019-09-03 12:39:13',NULL,'python-requests/2.22.0','--- Olga Krebs\n','people'),(289,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:13','2019-09-03 12:39:13',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(290,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:14','2019-09-03 12:39:14',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(291,'create',NULL,'Person',92,'User',1,NULL,NULL,'2019-09-03 12:39:14','2019-09-03 12:39:14',NULL,'python-requests/2.22.0','--- Wolfgang Müller\n','people'),(292,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:14','2019-09-03 12:39:14',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(293,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:15','2019-09-03 12:39:15',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(294,'create',NULL,'Person',93,'User',1,NULL,NULL,'2019-09-03 12:39:15','2019-09-03 12:39:15',NULL,'python-requests/2.22.0','--- Marcel Petrov\n','people'),(295,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:16','2019-09-03 12:39:16',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(296,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:16','2019-09-03 12:39:16',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(297,'create',NULL,'Person',94,'User',1,NULL,NULL,'2019-09-03 12:39:16','2019-09-03 12:39:16',NULL,'python-requests/2.22.0','--- Ina Pöhner\n','people'),(298,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:17','2019-09-03 12:39:17',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(299,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:17','2019-09-03 12:39:17',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(300,'create',NULL,'Person',95,'User',1,NULL,NULL,'2019-09-03 12:39:17','2019-09-03 12:39:17',NULL,'python-requests/2.22.0','--- Maja Rey\n','people'),(301,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:18','2019-09-03 12:39:18',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(302,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:18','2019-09-03 12:39:18',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(303,'create',NULL,'Person',96,'User',1,NULL,NULL,'2019-09-03 12:39:18','2019-09-03 12:39:18',NULL,'python-requests/2.22.0','--- Natalia Simous\n','people'),(304,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:19','2019-09-03 12:39:19',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(305,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:20','2019-09-03 12:39:20',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(306,'create',NULL,'Person',97,'User',1,NULL,NULL,'2019-09-03 12:39:20','2019-09-03 12:39:20',NULL,'python-requests/2.22.0','--- Andreas Weidemann\n','people'),(307,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:20','2019-09-03 12:39:20',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(308,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:21','2019-09-03 12:39:21',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(309,'create',NULL,'Person',98,'User',1,NULL,NULL,'2019-09-03 12:39:21','2019-09-03 12:39:21',NULL,'python-requests/2.22.0','--- Benjamin Winter\n','people'),(310,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:22','2019-09-03 12:39:22',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(311,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:22','2019-09-03 12:39:22',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(312,'create',NULL,'Person',99,'User',1,NULL,NULL,'2019-09-03 12:39:23','2019-09-03 12:39:23',NULL,'python-requests/2.22.0','--- Ulrike Wittig\n','people'),(313,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:23','2019-09-03 12:39:23',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(314,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:24','2019-09-03 12:39:24',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(315,'create',NULL,'Person',100,'User',1,NULL,NULL,'2019-09-03 12:39:24','2019-09-03 12:39:24',NULL,'python-requests/2.22.0','--- Dorotea Dudas\n','people'),(316,'show',NULL,'Project',2,NULL,NULL,NULL,NULL,'2019-09-03 12:39:25','2019-09-03 12:39:25',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(317,'update',NULL,'Project',2,'User',1,NULL,NULL,'2019-09-03 12:39:26','2019-09-03 12:39:26',NULL,'python-requests/2.22.0','--- Scientific Databases and Visualization\n','projects'),(318,'create',NULL,'User',1,'User',1,NULL,NULL,'2019-09-03 12:39:55','2019-09-03 12:39:55',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36',NULL,'sessions'),(319,'create',NULL,'User',1,'User',1,NULL,NULL,'2020-01-12 11:18:41','2020-01-12 11:18:41',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:72.0) Gecko/20100101 Firefox/72.0',NULL,'sessions'),(320,'show',NULL,'Person',100,'User',1,NULL,NULL,'2020-01-12 11:21:10','2020-01-12 11:21:10',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:72.0) Gecko/20100101 Firefox/72.0','--- Dorotea Dudas\n','people');
/*!40000 ALTER TABLE `activity_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admin_defined_role_programmes`
--

DROP TABLE IF EXISTS `admin_defined_role_programmes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_defined_role_programmes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `programme_id` int(11) DEFAULT NULL,
  `person_id` int(11) DEFAULT NULL,
  `role_mask` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_defined_role_programmes`
--

LOCK TABLES `admin_defined_role_programmes` WRITE;
/*!40000 ALTER TABLE `admin_defined_role_programmes` DISABLE KEYS */;
/*!40000 ALTER TABLE `admin_defined_role_programmes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `admin_defined_role_projects`
--

DROP TABLE IF EXISTS `admin_defined_role_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_defined_role_projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) DEFAULT NULL,
  `role_mask` int(11) DEFAULT NULL,
  `person_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_defined_role_projects`
--

LOCK TABLES `admin_defined_role_projects` WRITE;
/*!40000 ALTER TABLE `admin_defined_role_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `admin_defined_role_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `annotation_attributes`
--

DROP TABLE IF EXISTS `annotation_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `annotation_attributes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `identifier` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_annotation_attributes_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `annotation_attributes`
--

LOCK TABLES `annotation_attributes` WRITE;
/*!40000 ALTER TABLE `annotation_attributes` DISABLE KEYS */;
INSERT INTO `annotation_attributes` VALUES (1,'expertise','2019-09-03 12:32:49','2019-09-03 12:32:49','http://www.example.org/attribute#expertise'),(2,'tool','2019-09-03 12:32:50','2019-09-03 12:32:50','http://www.example.org/attribute#tool');
/*!40000 ALTER TABLE `annotation_attributes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `annotation_value_seeds`
--

DROP TABLE IF EXISTS `annotation_value_seeds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `annotation_value_seeds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attribute_id` int(11) NOT NULL,
  `old_value` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `value_type` varchar(50) NOT NULL DEFAULT 'FIXME',
  `value_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_annotation_value_seeds_on_attribute_id` (`attribute_id`)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `annotation_value_seeds`
--

LOCK TABLES `annotation_value_seeds` WRITE;
/*!40000 ALTER TABLE `annotation_value_seeds` DISABLE KEYS */;
INSERT INTO `annotation_value_seeds` VALUES (1,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',1),(2,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',2),(3,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',3),(4,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',4),(5,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',5),(6,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',6),(7,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',7),(8,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',8),(9,1,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',9),(10,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',10),(11,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',11),(12,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',12),(13,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',13),(14,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',14),(15,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',15),(16,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',16),(17,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',17),(18,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',18),(19,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',19),(20,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',20),(21,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',21),(22,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',4),(23,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',22),(24,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',23),(25,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',1),(26,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',24),(27,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',25),(28,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',26),(29,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',27),(30,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',28),(31,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',7),(32,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',29),(33,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',30),(34,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',31),(35,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',32),(36,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',33),(37,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',34),(38,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',35),(39,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',36),(40,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',37),(41,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',38),(42,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',39),(43,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',40),(44,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',41),(45,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',42),(46,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',43),(47,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',44),(48,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',45),(49,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',46),(50,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',47),(51,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',48),(52,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',49),(53,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',50),(54,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',51),(55,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',52),(56,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',53),(57,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',54),(58,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',55),(59,2,NULL,'2019-09-03 12:32:50','2019-09-03 12:32:50','TextValue',56);
/*!40000 ALTER TABLE `annotation_value_seeds` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `annotation_versions`
--

DROP TABLE IF EXISTS `annotation_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `annotation_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `annotation_id` int(11) NOT NULL,
  `version` int(11) NOT NULL,
  `version_creator_id` int(11) DEFAULT NULL,
  `source_type` varchar(255) NOT NULL,
  `source_id` int(11) NOT NULL,
  `annotatable_type` varchar(50) NOT NULL,
  `annotatable_id` int(11) NOT NULL,
  `attribute_id` int(11) NOT NULL,
  `old_value` varchar(255) DEFAULT '',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `value_type` varchar(50) NOT NULL DEFAULT 'FIXME',
  `value_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_annotation_versions_on_annotation_id` (`annotation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `annotation_versions`
--

LOCK TABLES `annotation_versions` WRITE;
/*!40000 ALTER TABLE `annotation_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `annotation_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `annotations`
--

DROP TABLE IF EXISTS `annotations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `annotations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source_type` varchar(255) NOT NULL,
  `source_id` int(11) NOT NULL,
  `annotatable_type` varchar(50) NOT NULL,
  `annotatable_id` int(11) NOT NULL,
  `attribute_id` int(11) NOT NULL,
  `old_value` varchar(255) DEFAULT '',
  `version` int(11) DEFAULT NULL,
  `version_creator_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `value_type` varchar(50) NOT NULL DEFAULT 'FIXME',
  `value_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_annotations_on_annotatable_type_and_annotatable_id` (`annotatable_type`,`annotatable_id`),
  KEY `index_annotations_on_attribute_id` (`attribute_id`),
  KEY `index_annotations_on_source_type_and_source_id` (`source_type`,`source_id`),
  KEY `index_annotations_on_value_type_and_value_id` (`value_type`,`value_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `annotations`
--

LOCK TABLES `annotations` WRITE;
/*!40000 ALTER TABLE `annotations` DISABLE KEYS */;
/*!40000 ALTER TABLE `annotations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ar_internal_metadata`
--

DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ar_internal_metadata`
--

LOCK TABLES `ar_internal_metadata` WRITE;
/*!40000 ALTER TABLE `ar_internal_metadata` DISABLE KEYS */;
INSERT INTO `ar_internal_metadata` VALUES ('environment','development','2019-09-03 12:32:46','2019-09-03 12:32:46');
/*!40000 ALTER TABLE `ar_internal_metadata` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assay_assets`
--

DROP TABLE IF EXISTS `assay_assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assay_assets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `assay_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `relationship_type_id` int(11) DEFAULT NULL,
  `asset_type` varchar(255) DEFAULT NULL,
  `direction` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_assay_assets_on_assay_id` (`assay_id`),
  KEY `index_assay_assets_on_asset_id_and_asset_type` (`asset_id`,`asset_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assay_assets`
--

LOCK TABLES `assay_assets` WRITE;
/*!40000 ALTER TABLE `assay_assets` DISABLE KEYS */;
/*!40000 ALTER TABLE `assay_assets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assay_auth_lookup`
--

DROP TABLE IF EXISTS `assay_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assay_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_assay_auth_lookup_on_user_id_and_asset_id_and_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_assay_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assay_auth_lookup`
--

LOCK TABLES `assay_auth_lookup` WRITE;
/*!40000 ALTER TABLE `assay_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `assay_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assay_classes`
--

DROP TABLE IF EXISTS `assay_classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assay_classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `key` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assay_classes`
--

LOCK TABLES `assay_classes` WRITE;
/*!40000 ALTER TABLE `assay_classes` DISABLE KEYS */;
INSERT INTO `assay_classes` VALUES (1,'Experimental assay',NULL,'2019-09-03 12:32:49','2019-09-03 12:32:49','EXP'),(2,'Modelling analysis',NULL,'2019-09-03 12:32:49','2019-09-03 12:32:49','MODEL');
/*!40000 ALTER TABLE `assay_classes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assay_organisms`
--

DROP TABLE IF EXISTS `assay_organisms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assay_organisms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `assay_id` int(11) DEFAULT NULL,
  `organism_id` int(11) DEFAULT NULL,
  `culture_growth_type_id` int(11) DEFAULT NULL,
  `strain_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `tissue_and_cell_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_assay_organisms_on_assay_id` (`assay_id`),
  KEY `index_assay_organisms_on_organism_id` (`organism_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assay_organisms`
--

LOCK TABLES `assay_organisms` WRITE;
/*!40000 ALTER TABLE `assay_organisms` DISABLE KEYS */;
/*!40000 ALTER TABLE `assay_organisms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assays`
--

DROP TABLE IF EXISTS `assays`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assays` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `study_id` int(11) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `assay_class_id` int(11) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `institution_id` int(11) DEFAULT NULL,
  `assay_type_uri` varchar(255) DEFAULT NULL,
  `technology_type_uri` varchar(255) DEFAULT NULL,
  `suggested_assay_type_id` int(11) DEFAULT NULL,
  `suggested_technology_type_id` int(11) DEFAULT NULL,
  `other_creators` text,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assays`
--

LOCK TABLES `assays` WRITE;
/*!40000 ALTER TABLE `assays` DISABLE KEYS */;
/*!40000 ALTER TABLE `assays` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `asset_doi_logs`
--

DROP TABLE IF EXISTS `asset_doi_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `asset_doi_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `asset_type` varchar(255) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `asset_version` int(11) DEFAULT NULL,
  `action` int(11) DEFAULT NULL,
  `comment` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asset_doi_logs`
--

LOCK TABLES `asset_doi_logs` WRITE;
/*!40000 ALTER TABLE `asset_doi_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `asset_doi_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assets`
--

DROP TABLE IF EXISTS `assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) DEFAULT NULL,
  `resource_type` varchar(255) DEFAULT NULL,
  `resource_id` int(11) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assets`
--

LOCK TABLES `assets` WRITE;
/*!40000 ALTER TABLE `assets` DISABLE KEYS */;
/*!40000 ALTER TABLE `assets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `assets_creators`
--

DROP TABLE IF EXISTS `assets_creators`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `assets_creators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `asset_id` int(11) DEFAULT NULL,
  `creator_id` int(11) DEFAULT NULL,
  `asset_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_assets_creators_on_asset_id_and_asset_type` (`asset_id`,`asset_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `assets_creators`
--

LOCK TABLES `assets_creators` WRITE;
/*!40000 ALTER TABLE `assets_creators` DISABLE KEYS */;
/*!40000 ALTER TABLE `assets_creators` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_lookup_update_queues`
--

DROP TABLE IF EXISTS `auth_lookup_update_queues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_lookup_update_queues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_id` int(11) DEFAULT NULL,
  `item_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `priority` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=102 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_lookup_update_queues`
--

LOCK TABLES `auth_lookup_update_queues` WRITE;
/*!40000 ALTER TABLE `auth_lookup_update_queues` DISABLE KEYS */;
INSERT INTO `auth_lookup_update_queues` VALUES (1,1,'User','2019-09-03 12:33:31','2019-09-03 12:33:31',2),(2,1,'Person','2019-09-03 12:33:33','2019-09-03 12:33:33',2),(3,2,'Person','2019-09-03 12:37:39','2019-09-03 12:37:39',2),(4,3,'Person','2019-09-03 12:37:40','2019-09-03 12:37:40',2),(5,4,'Person','2019-09-03 12:37:41','2019-09-03 12:37:41',2),(6,5,'Person','2019-09-03 12:37:42','2019-09-03 12:37:42',2),(7,6,'Person','2019-09-03 12:37:43','2019-09-03 12:37:43',2),(8,7,'Person','2019-09-03 12:37:44','2019-09-03 12:37:44',2),(9,8,'Person','2019-09-03 12:37:44','2019-09-03 12:37:44',2),(10,9,'Person','2019-09-03 12:37:45','2019-09-03 12:37:45',2),(11,10,'Person','2019-09-03 12:37:46','2019-09-03 12:37:46',2),(12,11,'Person','2019-09-03 12:37:47','2019-09-03 12:37:47',2),(13,12,'Person','2019-09-03 12:37:48','2019-09-03 12:37:48',2),(14,13,'Person','2019-09-03 12:37:49','2019-09-03 12:37:49',2),(15,14,'Person','2019-09-03 12:37:50','2019-09-03 12:37:50',2),(16,15,'Person','2019-09-03 12:37:51','2019-09-03 12:37:51',2),(17,16,'Person','2019-09-03 12:37:52','2019-09-03 12:37:52',2),(18,17,'Person','2019-09-03 12:37:53','2019-09-03 12:37:53',2),(19,18,'Person','2019-09-03 12:37:53','2019-09-03 12:37:53',2),(20,19,'Person','2019-09-03 12:37:54','2019-09-03 12:37:54',2),(21,20,'Person','2019-09-03 12:37:55','2019-09-03 12:37:55',2),(22,21,'Person','2019-09-03 12:37:56','2019-09-03 12:37:56',2),(23,22,'Person','2019-09-03 12:37:57','2019-09-03 12:37:57',2),(24,23,'Person','2019-09-03 12:37:58','2019-09-03 12:37:58',2),(25,24,'Person','2019-09-03 12:37:59','2019-09-03 12:37:59',2),(26,25,'Person','2019-09-03 12:38:00','2019-09-03 12:38:00',2),(27,26,'Person','2019-09-03 12:38:01','2019-09-03 12:38:01',2),(28,27,'Person','2019-09-03 12:38:02','2019-09-03 12:38:02',2),(29,28,'Person','2019-09-03 12:38:03','2019-09-03 12:38:03',2),(30,29,'Person','2019-09-03 12:38:04','2019-09-03 12:38:04',2),(31,30,'Person','2019-09-03 12:38:05','2019-09-03 12:38:05',2),(32,31,'Person','2019-09-03 12:38:06','2019-09-03 12:38:06',2),(33,32,'Person','2019-09-03 12:38:07','2019-09-03 12:38:07',2),(34,33,'Person','2019-09-03 12:38:08','2019-09-03 12:38:08',2),(35,34,'Person','2019-09-03 12:38:08','2019-09-03 12:38:08',2),(36,35,'Person','2019-09-03 12:38:09','2019-09-03 12:38:09',2),(37,36,'Person','2019-09-03 12:38:10','2019-09-03 12:38:10',2),(38,37,'Person','2019-09-03 12:38:11','2019-09-03 12:38:11',2),(39,38,'Person','2019-09-03 12:38:12','2019-09-03 12:38:12',2),(40,39,'Person','2019-09-03 12:38:13','2019-09-03 12:38:13',2),(41,40,'Person','2019-09-03 12:38:14','2019-09-03 12:38:14',2),(42,41,'Person','2019-09-03 12:38:15','2019-09-03 12:38:15',2),(43,42,'Person','2019-09-03 12:38:16','2019-09-03 12:38:16',2),(44,43,'Person','2019-09-03 12:38:17','2019-09-03 12:38:17',2),(45,44,'Person','2019-09-03 12:38:18','2019-09-03 12:38:18',2),(46,45,'Person','2019-09-03 12:38:19','2019-09-03 12:38:19',2),(47,46,'Person','2019-09-03 12:38:20','2019-09-03 12:38:20',2),(48,47,'Person','2019-09-03 12:38:22','2019-09-03 12:38:22',2),(49,48,'Person','2019-09-03 12:38:23','2019-09-03 12:38:23',2),(50,49,'Person','2019-09-03 12:38:24','2019-09-03 12:38:24',2),(51,50,'Person','2019-09-03 12:38:26','2019-09-03 12:38:26',2),(52,51,'Person','2019-09-03 12:38:28','2019-09-03 12:38:28',2),(53,52,'Person','2019-09-03 12:38:29','2019-09-03 12:38:29',2),(54,53,'Person','2019-09-03 12:38:31','2019-09-03 12:38:31',2),(55,54,'Person','2019-09-03 12:38:33','2019-09-03 12:38:33',2),(56,55,'Person','2019-09-03 12:38:35','2019-09-03 12:38:35',2),(57,56,'Person','2019-09-03 12:38:36','2019-09-03 12:38:36',2),(58,57,'Person','2019-09-03 12:38:37','2019-09-03 12:38:37',2),(59,58,'Person','2019-09-03 12:38:38','2019-09-03 12:38:38',2),(60,59,'Person','2019-09-03 12:38:39','2019-09-03 12:38:39',2),(61,60,'Person','2019-09-03 12:38:40','2019-09-03 12:38:40',2),(62,61,'Person','2019-09-03 12:38:41','2019-09-03 12:38:41',2),(63,62,'Person','2019-09-03 12:38:42','2019-09-03 12:38:42',2),(64,63,'Person','2019-09-03 12:38:43','2019-09-03 12:38:43',2),(65,64,'Person','2019-09-03 12:38:45','2019-09-03 12:38:45',2),(66,65,'Person','2019-09-03 12:38:46','2019-09-03 12:38:46',2),(67,66,'Person','2019-09-03 12:38:47','2019-09-03 12:38:47',2),(68,67,'Person','2019-09-03 12:38:48','2019-09-03 12:38:48',2),(69,68,'Person','2019-09-03 12:38:49','2019-09-03 12:38:49',2),(70,69,'Person','2019-09-03 12:38:49','2019-09-03 12:38:49',2),(71,70,'Person','2019-09-03 12:38:50','2019-09-03 12:38:50',2),(72,71,'Person','2019-09-03 12:38:51','2019-09-03 12:38:51',2),(73,72,'Person','2019-09-03 12:38:53','2019-09-03 12:38:53',2),(74,73,'Person','2019-09-03 12:38:54','2019-09-03 12:38:54',2),(75,74,'Person','2019-09-03 12:38:55','2019-09-03 12:38:55',2),(76,75,'Person','2019-09-03 12:38:56','2019-09-03 12:38:56',2),(77,76,'Person','2019-09-03 12:38:58','2019-09-03 12:38:58',2),(78,77,'Person','2019-09-03 12:38:59','2019-09-03 12:38:59',2),(79,78,'Person','2019-09-03 12:39:00','2019-09-03 12:39:00',2),(80,79,'Person','2019-09-03 12:39:01','2019-09-03 12:39:01',2),(81,80,'Person','2019-09-03 12:39:01','2019-09-03 12:39:01',2),(82,81,'Person','2019-09-03 12:39:02','2019-09-03 12:39:02',2),(83,82,'Person','2019-09-03 12:39:04','2019-09-03 12:39:04',2),(84,83,'Person','2019-09-03 12:39:05','2019-09-03 12:39:05',2),(85,84,'Person','2019-09-03 12:39:06','2019-09-03 12:39:06',2),(86,85,'Person','2019-09-03 12:39:07','2019-09-03 12:39:07',2),(87,86,'Person','2019-09-03 12:39:09','2019-09-03 12:39:09',2),(88,87,'Person','2019-09-03 12:39:10','2019-09-03 12:39:10',2),(89,88,'Person','2019-09-03 12:39:11','2019-09-03 12:39:11',2),(90,89,'Person','2019-09-03 12:39:12','2019-09-03 12:39:12',2),(91,90,'Person','2019-09-03 12:39:13','2019-09-03 12:39:13',2),(92,91,'Person','2019-09-03 12:39:14','2019-09-03 12:39:14',2),(93,92,'Person','2019-09-03 12:39:15','2019-09-03 12:39:15',2),(94,93,'Person','2019-09-03 12:39:16','2019-09-03 12:39:16',2),(95,94,'Person','2019-09-03 12:39:17','2019-09-03 12:39:17',2),(96,95,'Person','2019-09-03 12:39:18','2019-09-03 12:39:18',2),(97,96,'Person','2019-09-03 12:39:19','2019-09-03 12:39:19',2),(98,97,'Person','2019-09-03 12:39:20','2019-09-03 12:39:20',2),(99,98,'Person','2019-09-03 12:39:22','2019-09-03 12:39:22',2),(100,99,'Person','2019-09-03 12:39:23','2019-09-03 12:39:23',2),(101,100,'Person','2019-09-03 12:39:25','2019-09-03 12:39:25',2);
/*!40000 ALTER TABLE `auth_lookup_update_queues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `avatars`
--

DROP TABLE IF EXISTS `avatars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `avatars` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_type` varchar(255) DEFAULT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_avatars_on_owner_type_and_owner_id` (`owner_type`,`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `avatars`
--

LOCK TABLES `avatars` WRITE;
/*!40000 ALTER TABLE `avatars` DISABLE KEYS */;
/*!40000 ALTER TABLE `avatars` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bioportal_concepts`
--

DROP TABLE IF EXISTS `bioportal_concepts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bioportal_concepts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ontology_id` varchar(255) DEFAULT NULL,
  `concept_uri` varchar(255) DEFAULT NULL,
  `cached_concept_yaml` text,
  `conceptable_id` int(11) DEFAULT NULL,
  `conceptable_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bioportal_concepts`
--

LOCK TABLES `bioportal_concepts` WRITE;
/*!40000 ALTER TABLE `bioportal_concepts` DISABLE KEYS */;
INSERT INTO `bioportal_concepts` VALUES (1,'','',NULL,NULL,NULL);
/*!40000 ALTER TABLE `bioportal_concepts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cell_ranges`
--

DROP TABLE IF EXISTS `cell_ranges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cell_ranges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cell_range_id` int(11) DEFAULT NULL,
  `worksheet_id` int(11) DEFAULT NULL,
  `start_row` int(11) DEFAULT NULL,
  `start_column` int(11) DEFAULT NULL,
  `end_row` int(11) DEFAULT NULL,
  `end_column` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cell_ranges`
--

LOCK TABLES `cell_ranges` WRITE;
/*!40000 ALTER TABLE `cell_ranges` DISABLE KEYS */;
/*!40000 ALTER TABLE `cell_ranges` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `compounds`
--

DROP TABLE IF EXISTS `compounds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `compounds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=132 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compounds`
--

LOCK TABLES `compounds` WRITE;
/*!40000 ALTER TABLE `compounds` DISABLE KEYS */;
INSERT INTO `compounds` VALUES (1,'Acetate','2011-07-06 18:10:33','2011-07-06 18:10:33'),(2,'Alanine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(3,'Arginine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(4,'Aspartic acid','2011-07-06 18:10:33','2011-07-06 18:10:33'),(5,'CO2','2011-07-06 18:10:33','2011-07-06 18:10:33'),(6,'Cysteine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(7,'Formiate','2011-07-06 18:10:33','2011-07-06 18:10:33'),(8,'Glucose','2011-07-06 18:10:33','2011-07-06 18:10:33'),(9,'Glutamate','2011-07-06 18:10:33','2011-07-06 18:10:33'),(10,'Glycine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(11,'Histidine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(12,'Isoluecine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(13,'Lactate','2011-07-06 18:10:33','2011-07-06 18:10:33'),(14,'Leucine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(15,'Lysine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(16,'Methionine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(17,'NH3','2011-07-06 18:10:33','2011-07-06 18:10:33'),(18,'O2','2011-07-06 18:10:33','2011-07-06 18:10:33'),(19,'Ornithine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(20,'Phenylalanine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(21,'Proline','2011-07-06 18:10:33','2011-07-06 18:10:33'),(22,'Pyruvate','2011-07-06 18:10:33','2011-07-06 18:10:33'),(23,'Serine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(24,'Succinate','2011-07-06 18:10:33','2011-07-06 18:10:33'),(25,'Threonine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(26,'Tyrosine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(27,'Valine','2011-07-06 18:10:33','2011-07-06 18:10:33'),(28,'(2R)-2-Hydroxy-3-(phosphonooxy)-propanal','2011-08-25 16:29:21','2011-08-25 16:29:21'),(29,'(R)-2-Hydroxy-3-(phosphonooxy)-1-monoanhydride with phosphoric propanoic acid','2011-08-25 16:29:21','2011-08-25 16:29:21'),(30,'[(2R)-2-hydroxy-3-phosphonooxy-propanoyl]oxyphosphonic acid','2011-08-25 16:29:21','2011-08-25 16:29:21'),(31,'1,3-Bisphospho-D-glycerate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(32,'Glycerate 1,3-bisphosphate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(33,'1-glycerol-phosphate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(34,'2,3 Butanediol','2011-08-25 16:29:21','2011-08-25 16:29:21'),(35,'2-Dehydro-3-deoxy-6-phospho-D-gluconate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(36,'2-Dehydro-3-deoxy-D-gluconate 6-phosphate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(37,'dADP','2011-08-25 16:29:21','2011-08-25 16:29:21'),(38,'dATP','2011-08-25 16:29:21','2011-08-25 16:29:21'),(39,'2-Keto-3-deoxy-6-phosphogluconate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(40,'2-Oxoglutarate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(41,'2-oxoglutaric acid','2011-08-25 16:29:21','2011-08-25 16:29:21'),(42,'2-Phospho-D-glycerate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(43,'2-phospho-D-glyceric acid','2011-08-25 16:29:21','2011-08-25 16:29:21'),(44,'Phosphoenolpyruvate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(45,'Glycerate 3-phosphate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(46,'3-Phospho-D-glycerate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(47,'3-phospho-D-glyceric acid','2011-08-25 16:29:21','2011-08-25 16:29:21'),(48,'3-Phospho-D-glyceroyl phosphate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(49,'6-Phospho-2-dehydro-3-deoxy-D-gluconate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(50,'6-Phospho-D-gluconate','2011-08-25 16:29:21','2011-08-25 16:29:21'),(51,'6-phospho-D-gluconic acid','2011-08-25 16:29:21','2011-08-25 16:29:21'),(52,'6-Phospho-D-glucono-1,5-lactone','2011-08-25 16:29:21','2011-08-25 16:29:21'),(53,'6-Phosphogluconate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(54,'Acetaldehyde','2011-08-25 16:29:22','2011-08-25 16:29:22'),(55,'Acetoin','2011-08-25 16:29:22','2011-08-25 16:29:22'),(56,'Acetyl phosphate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(57,'Acetyl-CoA','2011-08-25 16:29:22','2011-08-25 16:29:22'),(58,'ADP','2011-08-25 16:29:22','2011-08-25 16:29:22'),(59,'ATP','2011-08-25 16:29:22','2011-08-25 16:29:22'),(60,'alpha-D-Glucose','2011-08-25 16:29:22','2011-08-25 16:29:22'),(61,'alpha-D-Glucose 6-phosphate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(62,'alpha-D-ribose 5-phosphate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(63,'AMP','2011-08-25 16:29:22','2011-08-25 16:29:22'),(64,'beta-D-Fructose 1,6-bisphosphate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(65,'beta-D-Fructose 6-phosphate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(66,'beta-D-Glucose','2011-08-25 16:29:22','2011-08-25 16:29:22'),(67,'beta-Nicotinamide adenine dinucleotide phosphate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(68,'CDP','2011-08-25 16:29:22','2011-08-25 16:29:22'),(69,'citaric acid','2011-08-25 16:29:22','2011-08-25 16:29:22'),(70,'Citrate','2011-08-25 16:29:22','2011-08-25 16:29:22'),(71,'CTP','2011-08-25 16:29:23','2011-08-25 16:29:23'),(72,'D-Erythrose 4-phosphate','2011-08-25 16:29:23','2011-08-25 16:29:23'),(73,'D-Glucose','2011-08-25 16:29:23','2011-08-25 16:29:23'),(74,'D-Fructose 1,6-bisphosphate','2011-08-25 16:29:23','2011-08-25 16:29:23'),(75,'D-Fructose 1-phosphate','2011-08-25 16:29:23','2011-08-25 16:29:23'),(76,'D-Fructose 6-phosphate','2011-08-25 16:29:23','2011-08-25 16:29:23'),(77,'D-Fructose, 6-(dihydrogen phosphate)','2011-08-25 16:29:23','2011-08-25 16:29:23'),(78,'D-Galactono-1,5-lactone','2011-08-25 16:29:23','2011-08-25 16:29:23'),(79,'D-Galactose','2011-08-25 16:29:23','2011-08-25 16:29:23'),(80,'D-Glucono-1,5-lactone','2011-08-25 16:29:23','2011-08-25 16:29:23'),(81,'D-Glucose 6-phosphate','2011-08-25 16:29:23','2011-08-25 16:29:23'),(82,'D-Glyceraldehyde','2011-08-25 16:29:23','2011-08-25 16:29:23'),(83,'D-Glyceraldehyde 3-phosphate','2011-08-25 16:29:23','2011-08-25 16:29:23'),(84,'Glycerone phosphate','2011-08-25 16:29:23','2011-08-25 16:29:23'),(85,'Diphosphopyridine nucleotide','2011-08-25 16:29:23','2011-08-25 16:29:23'),(86,'DPN','2011-08-25 16:29:23','2011-08-25 16:29:23'),(87,'NADH','2011-08-25 16:29:23','2011-08-25 16:29:23'),(88,'D-Xylonolactone','2011-08-25 16:29:24','2011-08-25 16:29:24'),(89,'D-Xylose','2011-08-25 16:29:24','2011-08-25 16:29:24'),(90,'Erythrose-4-phosphate','2011-08-25 16:29:24','2011-08-25 16:29:24'),(91,'Ethanol','2011-08-25 16:29:24','2011-08-25 16:29:24'),(92,'Formate','2011-08-25 16:29:24','2011-08-25 16:29:24'),(93,'fructose-6-phosphate','2011-08-25 16:29:24','2011-08-25 16:29:24'),(94,'Fumarate','2011-08-25 16:29:24','2011-08-25 16:29:24'),(95,'GDP','2011-08-25 16:29:24','2011-08-25 16:29:24'),(96,'Glucose 6-phosphate','2011-08-25 16:29:24','2011-08-25 16:29:24'),(97,'glyceraldehyde-3-phosphate','2011-08-25 16:29:24','2011-08-25 16:29:24'),(98,'Glycerol','2011-08-25 16:29:24','2011-08-25 16:29:24'),(99,'GTP','2011-08-25 16:29:24','2011-08-25 16:29:24'),(100,'H+','2011-08-25 16:29:24','2011-08-25 16:29:24'),(101,'H2O','2011-08-25 16:29:24','2011-08-25 16:29:24'),(102,'Hydrogen ion','2011-08-25 16:29:24','2011-08-25 16:29:24'),(103,'IDP','2011-08-25 16:29:24','2011-08-25 16:29:24'),(104,'IMP','2011-08-25 16:29:24','2011-08-25 16:29:24'),(105,'ITP','2011-08-25 16:29:24','2011-08-25 16:29:24'),(106,'Isocitrate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(107,'L-Malate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(108,'Malate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(109,'NAD','2011-08-25 16:29:25','2011-08-25 16:29:25'),(110,'NAD+','2011-08-25 16:29:25','2011-08-25 16:29:25'),(111,'Nadide','2011-08-25 16:29:25','2011-08-25 16:29:25'),(112,'NADP','2011-08-25 16:29:25','2011-08-25 16:29:25'),(113,'NADP+','2011-08-25 16:29:25','2011-08-25 16:29:25'),(114,'NADPH','2011-08-25 16:29:25','2011-08-25 16:29:25'),(115,'Nicotinamide adenine dinucleotide phosphate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(116,'Phosphate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(117,'Oxaloacetate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(118,'phosphoenol pyruvate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(119,'ribose-5-phosphate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(120,'ribulose-5-phosphate','2011-08-25 16:29:25','2011-08-25 16:29:25'),(121,'Succinyl-CoA','2011-08-25 16:29:25','2011-08-25 16:29:25'),(122,'TNP','2011-08-25 16:29:25','2011-08-25 16:29:25'),(123,'TPN','2011-08-25 16:29:25','2011-08-25 16:29:25'),(124,'alpha,alpha-Trehalose','2011-08-25 16:29:25','2011-08-25 16:29:25'),(125,'Triphosphopyridine nucleotide','2011-08-25 16:29:25','2011-08-25 16:29:25'),(126,'ubiquinol-8','2011-08-25 16:29:26','2011-08-25 16:29:26'),(127,'ubiquinone-8','2011-08-25 16:29:26','2011-08-25 16:29:26'),(128,'UDP','2011-08-25 16:29:26','2011-08-25 16:29:26'),(129,'UTP','2011-08-25 16:29:26','2011-08-25 16:29:26'),(130,'a-ketoglutarate','2011-08-25 16:29:26','2011-08-25 16:29:26'),(131,'balbal','2012-10-12 15:12:57','2012-10-12 15:12:57');
/*!40000 ALTER TABLE `compounds` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `content_blobs`
--

DROP TABLE IF EXISTS `content_blobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `content_blobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `md5sum` varchar(255) DEFAULT NULL,
  `url` text,
  `uuid` varchar(255) DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `content_type` varchar(255) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `asset_type` varchar(255) DEFAULT NULL,
  `asset_version` int(11) DEFAULT NULL,
  `is_webpage` tinyint(1) DEFAULT '0',
  `external_link` tinyint(1) DEFAULT NULL,
  `sha1sum` varchar(255) DEFAULT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_content_blobs_on_asset_id_and_asset_type` (`asset_id`,`asset_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `content_blobs`
--

LOCK TABLES `content_blobs` WRITE;
/*!40000 ALTER TABLE `content_blobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_blobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `culture_growth_types`
--

DROP TABLE IF EXISTS `culture_growth_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `culture_growth_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=940266200 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `culture_growth_types`
--

LOCK TABLES `culture_growth_types` WRITE;
/*!40000 ALTER TABLE `culture_growth_types` DISABLE KEYS */;
INSERT INTO `culture_growth_types` VALUES (932425129,'chemostat','2019-09-03 12:32:48','2019-09-03 12:32:48'),(940266199,'batch','2019-09-03 12:32:48','2019-09-03 12:32:48');
/*!40000 ALTER TABLE `culture_growth_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cultures`
--

DROP TABLE IF EXISTS `cultures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cultures` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `organism_id` int(11) DEFAULT NULL,
  `sop_id` int(11) DEFAULT NULL,
  `date_at_sampling` datetime DEFAULT NULL,
  `culture_start_date` datetime DEFAULT NULL,
  `age_at_sampling` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cultures`
--

LOCK TABLES `cultures` WRITE;
/*!40000 ALTER TABLE `cultures` DISABLE KEYS */;
/*!40000 ALTER TABLE `cultures` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_file_auth_lookup`
--

DROP TABLE IF EXISTS `data_file_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_file_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT NULL,
  `can_manage` tinyint(1) DEFAULT NULL,
  `can_edit` tinyint(1) DEFAULT NULL,
  `can_download` tinyint(1) DEFAULT NULL,
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_data_file_auth_lookup_user_asset_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_data_file_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_file_auth_lookup`
--

LOCK TABLES `data_file_auth_lookup` WRITE;
/*!40000 ALTER TABLE `data_file_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_file_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_file_versions`
--

DROP TABLE IF EXISTS `data_file_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_file_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `data_file_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `revision_comments` text,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `template_id` int(11) DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `simulation_data` tinyint(1) DEFAULT '0',
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_data_file_versions_contributor` (`contributor_id`),
  KEY `index_data_file_versions_on_data_file_id` (`data_file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_file_versions`
--

LOCK TABLES `data_file_versions` WRITE;
/*!40000 ALTER TABLE `data_file_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_file_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_file_versions_projects`
--

DROP TABLE IF EXISTS `data_file_versions_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_file_versions_projects` (
  `project_id` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_file_versions_projects`
--

LOCK TABLES `data_file_versions_projects` WRITE;
/*!40000 ALTER TABLE `data_file_versions_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_file_versions_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_files`
--

DROP TABLE IF EXISTS `data_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `template_id` int(11) DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `version` int(11) DEFAULT '1',
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `simulation_data` tinyint(1) DEFAULT '0',
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_data_files_on_contributor` (`contributor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_files`
--

LOCK TABLES `data_files` WRITE;
/*!40000 ALTER TABLE `data_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_files_events`
--

DROP TABLE IF EXISTS `data_files_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_files_events` (
  `data_file_id` int(11) DEFAULT NULL,
  `event_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_files_events`
--

LOCK TABLES `data_files_events` WRITE;
/*!40000 ALTER TABLE `data_files_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_files_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_files_projects`
--

DROP TABLE IF EXISTS `data_files_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `data_files_projects` (
  `project_id` int(11) DEFAULT NULL,
  `data_file_id` int(11) DEFAULT NULL,
  KEY `index_data_files_projects_on_data_file_id_and_project_id` (`data_file_id`,`project_id`),
  KEY `index_data_files_projects_on_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `data_files_projects`
--

LOCK TABLES `data_files_projects` WRITE;
/*!40000 ALTER TABLE `data_files_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_files_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `db_files`
--

DROP TABLE IF EXISTS `db_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `db_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `data` blob,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `db_files`
--

LOCK TABLES `db_files` WRITE;
/*!40000 ALTER TABLE `db_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `db_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `delayed_jobs`
--

DROP TABLE IF EXISTS `delayed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) DEFAULT '0',
  `attempts` int(11) DEFAULT '0',
  `handler` text,
  `last_error` text,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) DEFAULT NULL,
  `queue` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `delayed_jobs_priority` (`priority`,`run_at`)
) ENGINE=InnoDB AUTO_INCREMENT=344 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delayed_jobs`
--

LOCK TABLES `delayed_jobs` WRITE;
/*!40000 ALTER TABLE `delayed_jobs` DISABLE KEYS */;
INSERT INTO `delayed_jobs` VALUES (1,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 1\nrefresh_dependents: true\n',NULL,'2019-09-03 12:32:54',NULL,NULL,NULL,'default','2019-09-03 12:32:51','2019-09-03 12:32:51'),(2,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Institution\nitem_id: 1\nrefresh_dependents: true\n',NULL,'2019-09-03 12:32:55',NULL,NULL,NULL,'default','2019-09-03 12:32:52','2019-09-03 12:32:52'),(3,3,0,'--- !ruby/object:SendPeriodicEmailsJob\nfrequency: daily\n',NULL,'2019-09-04 10:00:00',NULL,NULL,NULL,'default','2019-09-03 12:33:10','2019-09-03 12:33:10'),(4,3,0,'--- !ruby/object:SendPeriodicEmailsJob\nfrequency: weekly\n',NULL,'2019-09-04 10:05:00',NULL,NULL,NULL,'default','2019-09-03 12:33:10','2019-09-03 12:33:10'),(5,3,0,'--- !ruby/object:SendPeriodicEmailsJob\nfrequency: monthly\n',NULL,'2019-09-04 10:10:00',NULL,NULL,NULL,'default','2019-09-03 12:33:10','2019-09-03 12:33:10'),(6,3,0,'--- !ruby/object:NewsFeedRefreshJob {}\n',NULL,'2019-09-03 12:33:13',NULL,NULL,NULL,'default','2019-09-03 12:33:10','2019-09-03 12:33:10'),(7,3,0,'--- !ruby/object:ContentBlobCleanerJob {}\n',NULL,'2019-09-03 12:33:13',NULL,NULL,NULL,'default','2019-09-03 12:33:10','2019-09-03 12:33:10'),(8,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:33:34',NULL,NULL,NULL,'authlookup','2019-09-03 12:33:31','2019-09-03 12:33:31'),(9,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 2\nrefresh_dependents: true\n',NULL,'2019-09-03 12:33:35',NULL,NULL,NULL,'default','2019-09-03 12:33:32','2019-09-03 12:33:32'),(10,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Institution\nitem_id: 2\nrefresh_dependents: true\n',NULL,'2019-09-03 12:33:35',NULL,NULL,NULL,'default','2019-09-03 12:33:32','2019-09-03 12:33:32'),(11,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 1\n',NULL,'2019-09-03 12:33:48',NULL,NULL,NULL,'default','2019-09-03 12:33:33','2019-09-03 12:33:33'),(12,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 2\n',NULL,'2019-09-03 12:33:48',NULL,NULL,NULL,'default','2019-09-03 12:33:33','2019-09-03 12:33:33'),(13,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 1\nrefresh_dependents: true\n',NULL,'2019-09-03 12:33:36',NULL,NULL,NULL,'default','2019-09-03 12:33:33','2019-09-03 12:33:33'),(14,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:33:36',NULL,NULL,NULL,'authlookup','2019-09-03 12:33:33','2019-09-03 12:33:33'),(15,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:33:36',NULL,NULL,NULL,'authlookup','2019-09-03 12:33:33','2019-09-03 12:33:33'),(16,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:33:36',NULL,NULL,NULL,'authlookup','2019-09-03 12:33:33','2019-09-03 12:33:33'),(17,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 3\nrefresh_dependents: true\n',NULL,'2019-09-03 12:34:41',NULL,NULL,NULL,'default','2019-09-03 12:34:38','2019-09-03 12:34:38'),(18,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 4\nrefresh_dependents: true\n',NULL,'2019-09-03 12:34:49',NULL,NULL,NULL,'default','2019-09-03 12:34:46','2019-09-03 12:34:46'),(19,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 5\nrefresh_dependents: true\n',NULL,'2019-09-03 12:34:55',NULL,NULL,NULL,'default','2019-09-03 12:34:52','2019-09-03 12:34:52'),(20,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 6\nrefresh_dependents: true\n',NULL,'2019-09-03 12:35:01',NULL,NULL,NULL,'default','2019-09-03 12:34:58','2019-09-03 12:34:58'),(21,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 7\nrefresh_dependents: true\n',NULL,'2019-09-03 12:35:10',NULL,NULL,NULL,'default','2019-09-03 12:35:07','2019-09-03 12:35:07'),(22,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 8\nrefresh_dependents: true\n',NULL,'2019-09-03 12:35:51',NULL,NULL,NULL,'default','2019-09-03 12:35:48','2019-09-03 12:35:48'),(23,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 9\nrefresh_dependents: true\n',NULL,'2019-09-03 12:35:57',NULL,NULL,NULL,'default','2019-09-03 12:35:54','2019-09-03 12:35:54'),(24,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 10\nrefresh_dependents: true\n',NULL,'2019-09-03 12:36:08',NULL,NULL,NULL,'default','2019-09-03 12:36:05','2019-09-03 12:36:05'),(25,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 11\nrefresh_dependents: true\n',NULL,'2019-09-03 12:36:15',NULL,NULL,NULL,'default','2019-09-03 12:36:12','2019-09-03 12:36:12'),(26,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 12\nrefresh_dependents: true\n',NULL,'2019-09-03 12:36:19',NULL,NULL,NULL,'default','2019-09-03 12:36:16','2019-09-03 12:36:16'),(27,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 3\n',NULL,'2019-09-03 12:36:41',NULL,NULL,NULL,'default','2019-09-03 12:36:26','2019-09-03 12:36:26'),(28,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:29',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:26','2019-09-03 12:36:26'),(29,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 4\n',NULL,'2019-09-03 12:36:41',NULL,NULL,NULL,'default','2019-09-03 12:36:26','2019-09-03 12:36:26'),(30,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:29',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:26','2019-09-03 12:36:26'),(31,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 5\n',NULL,'2019-09-03 12:36:42',NULL,NULL,NULL,'default','2019-09-03 12:36:27','2019-09-03 12:36:27'),(32,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:30',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:27','2019-09-03 12:36:27'),(33,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 6\n',NULL,'2019-09-03 12:36:42',NULL,NULL,NULL,'default','2019-09-03 12:36:27','2019-09-03 12:36:27'),(34,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:30',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:27','2019-09-03 12:36:27'),(35,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 7\n',NULL,'2019-09-03 12:36:42',NULL,NULL,NULL,'default','2019-09-03 12:36:27','2019-09-03 12:36:27'),(36,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:30',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:28','2019-09-03 12:36:28'),(37,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 8\n',NULL,'2019-09-03 12:36:43',NULL,NULL,NULL,'default','2019-09-03 12:36:28','2019-09-03 12:36:28'),(38,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:31',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:28','2019-09-03 12:36:28'),(39,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 9\n',NULL,'2019-09-03 12:36:43',NULL,NULL,NULL,'default','2019-09-03 12:36:28','2019-09-03 12:36:28'),(40,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:31',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:28','2019-09-03 12:36:28'),(41,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 10\n',NULL,'2019-09-03 12:36:44',NULL,NULL,NULL,'default','2019-09-03 12:36:29','2019-09-03 12:36:29'),(42,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:32',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:29','2019-09-03 12:36:29'),(43,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 11\n',NULL,'2019-09-03 12:36:44',NULL,NULL,NULL,'default','2019-09-03 12:36:29','2019-09-03 12:36:29'),(44,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:32',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:29','2019-09-03 12:36:29'),(45,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 12\n',NULL,'2019-09-03 12:36:44',NULL,NULL,NULL,'default','2019-09-03 12:36:29','2019-09-03 12:36:29'),(46,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:36:33',NULL,NULL,NULL,'authlookup','2019-09-03 12:36:30','2019-09-03 12:36:30'),(47,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 2\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:42',NULL,NULL,NULL,'default','2019-09-03 12:37:39','2019-09-03 12:37:39'),(48,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 13\n',NULL,'2019-09-03 12:37:54',NULL,NULL,NULL,'default','2019-09-03 12:37:39','2019-09-03 12:37:39'),(49,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:42',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:39','2019-09-03 12:37:39'),(50,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 3\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:42',NULL,NULL,NULL,'default','2019-09-03 12:37:39','2019-09-03 12:37:39'),(51,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 14\n',NULL,'2019-09-03 12:37:55',NULL,NULL,NULL,'default','2019-09-03 12:37:40','2019-09-03 12:37:40'),(52,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:43',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:40','2019-09-03 12:37:40'),(53,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 4\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:43',NULL,NULL,NULL,'default','2019-09-03 12:37:40','2019-09-03 12:37:40'),(54,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 15\n',NULL,'2019-09-03 12:37:56',NULL,NULL,NULL,'default','2019-09-03 12:37:41','2019-09-03 12:37:41'),(55,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:44',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:41','2019-09-03 12:37:41'),(56,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 5\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:44',NULL,NULL,NULL,'default','2019-09-03 12:37:41','2019-09-03 12:37:41'),(57,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 16\n',NULL,'2019-09-03 12:37:57',NULL,NULL,NULL,'default','2019-09-03 12:37:42','2019-09-03 12:37:42'),(58,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:45',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:42','2019-09-03 12:37:42'),(59,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 6\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:45',NULL,NULL,NULL,'default','2019-09-03 12:37:42','2019-09-03 12:37:42'),(60,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 17\n',NULL,'2019-09-03 12:37:58',NULL,NULL,NULL,'default','2019-09-03 12:37:43','2019-09-03 12:37:43'),(61,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:46',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:43','2019-09-03 12:37:43'),(62,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 7\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:46',NULL,NULL,NULL,'default','2019-09-03 12:37:43','2019-09-03 12:37:43'),(63,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 18\n',NULL,'2019-09-03 12:37:59',NULL,NULL,NULL,'default','2019-09-03 12:37:44','2019-09-03 12:37:44'),(64,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:47',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:44','2019-09-03 12:37:44'),(65,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 8\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:47',NULL,NULL,NULL,'default','2019-09-03 12:37:44','2019-09-03 12:37:44'),(66,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 19\n',NULL,'2019-09-03 12:37:59',NULL,NULL,NULL,'default','2019-09-03 12:37:44','2019-09-03 12:37:44'),(67,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:47',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:44','2019-09-03 12:37:44'),(68,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 9\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:48',NULL,NULL,NULL,'default','2019-09-03 12:37:45','2019-09-03 12:37:45'),(69,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 20\n',NULL,'2019-09-03 12:38:00',NULL,NULL,NULL,'default','2019-09-03 12:37:45','2019-09-03 12:37:45'),(70,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:48',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:45','2019-09-03 12:37:45'),(71,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 10\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:48',NULL,NULL,NULL,'default','2019-09-03 12:37:45','2019-09-03 12:37:45'),(72,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 21\n',NULL,'2019-09-03 12:38:01',NULL,NULL,NULL,'default','2019-09-03 12:37:46','2019-09-03 12:37:46'),(73,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:49',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:46','2019-09-03 12:37:46'),(74,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 11\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:49',NULL,NULL,NULL,'default','2019-09-03 12:37:46','2019-09-03 12:37:46'),(75,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 22\n',NULL,'2019-09-03 12:38:02',NULL,NULL,NULL,'default','2019-09-03 12:37:47','2019-09-03 12:37:47'),(76,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:50',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:47','2019-09-03 12:37:47'),(77,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 12\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:50',NULL,NULL,NULL,'default','2019-09-03 12:37:47','2019-09-03 12:37:47'),(78,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 23\n',NULL,'2019-09-03 12:38:03',NULL,NULL,NULL,'default','2019-09-03 12:37:48','2019-09-03 12:37:48'),(79,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:51',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:48','2019-09-03 12:37:48'),(80,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 13\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:51',NULL,NULL,NULL,'default','2019-09-03 12:37:48','2019-09-03 12:37:48'),(81,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 24\n',NULL,'2019-09-03 12:38:04',NULL,NULL,NULL,'default','2019-09-03 12:37:49','2019-09-03 12:37:49'),(82,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:52',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:49','2019-09-03 12:37:49'),(83,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 14\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:52',NULL,NULL,NULL,'default','2019-09-03 12:37:49','2019-09-03 12:37:49'),(84,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 25\n',NULL,'2019-09-03 12:38:05',NULL,NULL,NULL,'default','2019-09-03 12:37:50','2019-09-03 12:37:50'),(85,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:53',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:50','2019-09-03 12:37:50'),(86,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 15\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:53',NULL,NULL,NULL,'default','2019-09-03 12:37:50','2019-09-03 12:37:50'),(87,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 26\n',NULL,'2019-09-03 12:38:06',NULL,NULL,NULL,'default','2019-09-03 12:37:51','2019-09-03 12:37:51'),(88,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:54',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:51','2019-09-03 12:37:51'),(89,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 16\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:54',NULL,NULL,NULL,'default','2019-09-03 12:37:51','2019-09-03 12:37:51'),(90,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 27\n',NULL,'2019-09-03 12:38:07',NULL,NULL,NULL,'default','2019-09-03 12:37:52','2019-09-03 12:37:52'),(91,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:55',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:52','2019-09-03 12:37:52'),(92,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 17\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:55',NULL,NULL,NULL,'default','2019-09-03 12:37:52','2019-09-03 12:37:52'),(93,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 28\n',NULL,'2019-09-03 12:38:08',NULL,NULL,NULL,'default','2019-09-03 12:37:53','2019-09-03 12:37:53'),(94,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:56',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:53','2019-09-03 12:37:53'),(95,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 18\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:56',NULL,NULL,NULL,'default','2019-09-03 12:37:53','2019-09-03 12:37:53'),(96,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 29\n',NULL,'2019-09-03 12:38:08',NULL,NULL,NULL,'default','2019-09-03 12:37:53','2019-09-03 12:37:53'),(97,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:56',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:53','2019-09-03 12:37:53'),(98,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 19\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:57',NULL,NULL,NULL,'default','2019-09-03 12:37:54','2019-09-03 12:37:54'),(99,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 30\n',NULL,'2019-09-03 12:38:09',NULL,NULL,NULL,'default','2019-09-03 12:37:54','2019-09-03 12:37:54'),(100,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:57',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:54','2019-09-03 12:37:54'),(101,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 20\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:58',NULL,NULL,NULL,'default','2019-09-03 12:37:55','2019-09-03 12:37:55'),(102,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 31\n',NULL,'2019-09-03 12:38:10',NULL,NULL,NULL,'default','2019-09-03 12:37:55','2019-09-03 12:37:55'),(103,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:58',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:55','2019-09-03 12:37:55'),(104,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 21\nrefresh_dependents: true\n',NULL,'2019-09-03 12:37:59',NULL,NULL,NULL,'default','2019-09-03 12:37:56','2019-09-03 12:37:56'),(105,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 32\n',NULL,'2019-09-03 12:38:11',NULL,NULL,NULL,'default','2019-09-03 12:37:56','2019-09-03 12:37:56'),(106,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:37:59',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:56','2019-09-03 12:37:56'),(107,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 22\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:00',NULL,NULL,NULL,'default','2019-09-03 12:37:57','2019-09-03 12:37:57'),(108,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 33\n',NULL,'2019-09-03 12:38:12',NULL,NULL,NULL,'default','2019-09-03 12:37:57','2019-09-03 12:37:57'),(109,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:00',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:57','2019-09-03 12:37:57'),(110,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 23\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:01',NULL,NULL,NULL,'default','2019-09-03 12:37:58','2019-09-03 12:37:58'),(111,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 34\n',NULL,'2019-09-03 12:38:13',NULL,NULL,NULL,'default','2019-09-03 12:37:58','2019-09-03 12:37:58'),(112,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:01',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:58','2019-09-03 12:37:58'),(113,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 24\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:01',NULL,NULL,NULL,'default','2019-09-03 12:37:58','2019-09-03 12:37:58'),(114,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 35\n',NULL,'2019-09-03 12:38:14',NULL,NULL,NULL,'default','2019-09-03 12:37:59','2019-09-03 12:37:59'),(115,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:02',NULL,NULL,NULL,'authlookup','2019-09-03 12:37:59','2019-09-03 12:37:59'),(116,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 25\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:02',NULL,NULL,NULL,'default','2019-09-03 12:37:59','2019-09-03 12:37:59'),(117,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 36\n',NULL,'2019-09-03 12:38:15',NULL,NULL,NULL,'default','2019-09-03 12:38:00','2019-09-03 12:38:00'),(118,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:03',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:00','2019-09-03 12:38:00'),(119,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 26\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:03',NULL,NULL,NULL,'default','2019-09-03 12:38:00','2019-09-03 12:38:00'),(120,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 37\n',NULL,'2019-09-03 12:38:16',NULL,NULL,NULL,'default','2019-09-03 12:38:01','2019-09-03 12:38:01'),(121,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:04',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:01','2019-09-03 12:38:01'),(122,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 27\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:04',NULL,NULL,NULL,'default','2019-09-03 12:38:01','2019-09-03 12:38:01'),(123,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 38\n',NULL,'2019-09-03 12:38:16',NULL,NULL,NULL,'default','2019-09-03 12:38:01','2019-09-03 12:38:01'),(124,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:05',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:02','2019-09-03 12:38:02'),(125,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 28\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:05',NULL,NULL,NULL,'default','2019-09-03 12:38:02','2019-09-03 12:38:02'),(126,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 39\n',NULL,'2019-09-03 12:38:18',NULL,NULL,NULL,'default','2019-09-03 12:38:03','2019-09-03 12:38:03'),(127,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:06',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:03','2019-09-03 12:38:03'),(128,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 29\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:06',NULL,NULL,NULL,'default','2019-09-03 12:38:03','2019-09-03 12:38:03'),(129,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 40\n',NULL,'2019-09-03 12:38:19',NULL,NULL,NULL,'default','2019-09-03 12:38:04','2019-09-03 12:38:04'),(130,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:07',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:04','2019-09-03 12:38:04'),(131,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 30\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:07',NULL,NULL,NULL,'default','2019-09-03 12:38:04','2019-09-03 12:38:04'),(132,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 41\n',NULL,'2019-09-03 12:38:20',NULL,NULL,NULL,'default','2019-09-03 12:38:05','2019-09-03 12:38:05'),(133,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:08',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:05','2019-09-03 12:38:05'),(134,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 31\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:09',NULL,NULL,NULL,'default','2019-09-03 12:38:06','2019-09-03 12:38:06'),(135,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 42\n',NULL,'2019-09-03 12:38:21',NULL,NULL,NULL,'default','2019-09-03 12:38:06','2019-09-03 12:38:06'),(136,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:09',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:06','2019-09-03 12:38:06'),(137,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 32\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:09',NULL,NULL,NULL,'default','2019-09-03 12:38:06','2019-09-03 12:38:06'),(138,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 43\n',NULL,'2019-09-03 12:38:22',NULL,NULL,NULL,'default','2019-09-03 12:38:07','2019-09-03 12:38:07'),(139,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:10',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:07','2019-09-03 12:38:07'),(140,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 33\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:10',NULL,NULL,NULL,'default','2019-09-03 12:38:07','2019-09-03 12:38:07'),(141,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 44\n',NULL,'2019-09-03 12:38:23',NULL,NULL,NULL,'default','2019-09-03 12:38:08','2019-09-03 12:38:08'),(142,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:11',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:08','2019-09-03 12:38:08'),(143,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 34\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:11',NULL,NULL,NULL,'default','2019-09-03 12:38:08','2019-09-03 12:38:08'),(144,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 45\n',NULL,'2019-09-03 12:38:23',NULL,NULL,NULL,'default','2019-09-03 12:38:08','2019-09-03 12:38:08'),(145,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:11',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:08','2019-09-03 12:38:08'),(146,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 35\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:12',NULL,NULL,NULL,'default','2019-09-03 12:38:09','2019-09-03 12:38:09'),(147,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 46\n',NULL,'2019-09-03 12:38:24',NULL,NULL,NULL,'default','2019-09-03 12:38:09','2019-09-03 12:38:09'),(148,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:12',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:09','2019-09-03 12:38:09'),(149,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 36\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:13',NULL,NULL,NULL,'default','2019-09-03 12:38:10','2019-09-03 12:38:10'),(150,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 47\n',NULL,'2019-09-03 12:38:25',NULL,NULL,NULL,'default','2019-09-03 12:38:10','2019-09-03 12:38:10'),(151,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:13',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:10','2019-09-03 12:38:10'),(152,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 37\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:14',NULL,NULL,NULL,'default','2019-09-03 12:38:11','2019-09-03 12:38:11'),(153,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 48\n',NULL,'2019-09-03 12:38:26',NULL,NULL,NULL,'default','2019-09-03 12:38:11','2019-09-03 12:38:11'),(154,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:14',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:11','2019-09-03 12:38:11'),(155,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 38\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:15',NULL,NULL,NULL,'default','2019-09-03 12:38:12','2019-09-03 12:38:12'),(156,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 49\n',NULL,'2019-09-03 12:38:27',NULL,NULL,NULL,'default','2019-09-03 12:38:12','2019-09-03 12:38:12'),(157,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:15',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:12','2019-09-03 12:38:12'),(158,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 39\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:16',NULL,NULL,NULL,'default','2019-09-03 12:38:13','2019-09-03 12:38:13'),(159,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 50\n',NULL,'2019-09-03 12:38:28',NULL,NULL,NULL,'default','2019-09-03 12:38:13','2019-09-03 12:38:13'),(160,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:16',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:13','2019-09-03 12:38:13'),(161,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 40\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:16',NULL,NULL,NULL,'default','2019-09-03 12:38:13','2019-09-03 12:38:13'),(162,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 51\n',NULL,'2019-09-03 12:38:29',NULL,NULL,NULL,'default','2019-09-03 12:38:14','2019-09-03 12:38:14'),(163,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:17',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:14','2019-09-03 12:38:14'),(164,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 41\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:17',NULL,NULL,NULL,'default','2019-09-03 12:38:14','2019-09-03 12:38:14'),(165,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 52\n',NULL,'2019-09-03 12:38:30',NULL,NULL,NULL,'default','2019-09-03 12:38:15','2019-09-03 12:38:15'),(166,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:18',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:15','2019-09-03 12:38:15'),(167,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 42\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:18',NULL,NULL,NULL,'default','2019-09-03 12:38:15','2019-09-03 12:38:15'),(168,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 53\n',NULL,'2019-09-03 12:38:31',NULL,NULL,NULL,'default','2019-09-03 12:38:16','2019-09-03 12:38:16'),(169,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:19',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:16','2019-09-03 12:38:16'),(170,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 43\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:19',NULL,NULL,NULL,'default','2019-09-03 12:38:16','2019-09-03 12:38:16'),(171,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 54\n',NULL,'2019-09-03 12:38:32',NULL,NULL,NULL,'default','2019-09-03 12:38:17','2019-09-03 12:38:17'),(172,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:20',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:17','2019-09-03 12:38:17'),(173,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 44\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:20',NULL,NULL,NULL,'default','2019-09-03 12:38:17','2019-09-03 12:38:17'),(174,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 55\n',NULL,'2019-09-03 12:38:33',NULL,NULL,NULL,'default','2019-09-03 12:38:18','2019-09-03 12:38:18'),(175,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:21',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:18','2019-09-03 12:38:18'),(176,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 45\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:21',NULL,NULL,NULL,'default','2019-09-03 12:38:18','2019-09-03 12:38:18'),(177,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 56\n',NULL,'2019-09-03 12:38:34',NULL,NULL,NULL,'default','2019-09-03 12:38:19','2019-09-03 12:38:19'),(178,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:22',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:19','2019-09-03 12:38:19'),(179,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 46\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:23',NULL,NULL,NULL,'default','2019-09-03 12:38:20','2019-09-03 12:38:20'),(180,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 57\n',NULL,'2019-09-03 12:38:35',NULL,NULL,NULL,'default','2019-09-03 12:38:20','2019-09-03 12:38:20'),(181,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:23',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:20','2019-09-03 12:38:20'),(182,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 47\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:24',NULL,NULL,NULL,'default','2019-09-03 12:38:21','2019-09-03 12:38:21'),(183,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 58\n',NULL,'2019-09-03 12:38:37',NULL,NULL,NULL,'default','2019-09-03 12:38:22','2019-09-03 12:38:22'),(184,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:25',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:22','2019-09-03 12:38:22'),(185,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 48\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:25',NULL,NULL,NULL,'default','2019-09-03 12:38:22','2019-09-03 12:38:22'),(186,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 59\n',NULL,'2019-09-03 12:38:38',NULL,NULL,NULL,'default','2019-09-03 12:38:23','2019-09-03 12:38:23'),(187,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:26',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:23','2019-09-03 12:38:23'),(188,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 49\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:26',NULL,NULL,NULL,'default','2019-09-03 12:38:23','2019-09-03 12:38:23'),(189,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 60\n',NULL,'2019-09-03 12:38:39',NULL,NULL,NULL,'default','2019-09-03 12:38:24','2019-09-03 12:38:24'),(190,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:27',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:24','2019-09-03 12:38:24'),(191,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 50\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:28',NULL,NULL,NULL,'default','2019-09-03 12:38:25','2019-09-03 12:38:25'),(192,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 61\n',NULL,'2019-09-03 12:38:41',NULL,NULL,NULL,'default','2019-09-03 12:38:26','2019-09-03 12:38:26'),(193,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:29',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:26','2019-09-03 12:38:26'),(194,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 51\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:30',NULL,NULL,NULL,'default','2019-09-03 12:38:27','2019-09-03 12:38:27'),(195,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 62\n',NULL,'2019-09-03 12:38:43',NULL,NULL,NULL,'default','2019-09-03 12:38:28','2019-09-03 12:38:28'),(196,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:31',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:28','2019-09-03 12:38:28'),(197,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 52\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:31',NULL,NULL,NULL,'default','2019-09-03 12:38:28','2019-09-03 12:38:28'),(198,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 63\n',NULL,'2019-09-03 12:38:44',NULL,NULL,NULL,'default','2019-09-03 12:38:29','2019-09-03 12:38:29'),(199,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:32',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:29','2019-09-03 12:38:29'),(200,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 53\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:33',NULL,NULL,NULL,'default','2019-09-03 12:38:30','2019-09-03 12:38:30'),(201,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 64\n',NULL,'2019-09-03 12:38:46',NULL,NULL,NULL,'default','2019-09-03 12:38:31','2019-09-03 12:38:31'),(202,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:34',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:31','2019-09-03 12:38:31'),(203,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 54\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:35',NULL,NULL,NULL,'default','2019-09-03 12:38:32','2019-09-03 12:38:32'),(204,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 65\n',NULL,'2019-09-03 12:38:48',NULL,NULL,NULL,'default','2019-09-03 12:38:33','2019-09-03 12:38:33'),(205,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:36',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:33','2019-09-03 12:38:33'),(206,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 55\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:37',NULL,NULL,NULL,'default','2019-09-03 12:38:34','2019-09-03 12:38:34'),(207,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 66\n',NULL,'2019-09-03 12:38:50',NULL,NULL,NULL,'default','2019-09-03 12:38:35','2019-09-03 12:38:35'),(208,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:38',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:35','2019-09-03 12:38:35'),(209,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 56\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:39',NULL,NULL,NULL,'default','2019-09-03 12:38:36','2019-09-03 12:38:36'),(210,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 67\n',NULL,'2019-09-03 12:38:51',NULL,NULL,NULL,'default','2019-09-03 12:38:36','2019-09-03 12:38:36'),(211,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:39',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:36','2019-09-03 12:38:36'),(212,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 57\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:40',NULL,NULL,NULL,'default','2019-09-03 12:38:37','2019-09-03 12:38:37'),(213,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 68\n',NULL,'2019-09-03 12:38:52',NULL,NULL,NULL,'default','2019-09-03 12:38:37','2019-09-03 12:38:37'),(214,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:40',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:37','2019-09-03 12:38:37'),(215,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 58\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:40',NULL,NULL,NULL,'default','2019-09-03 12:38:37','2019-09-03 12:38:37'),(216,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 69\n',NULL,'2019-09-03 12:38:53',NULL,NULL,NULL,'default','2019-09-03 12:38:38','2019-09-03 12:38:38'),(217,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:41',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:38','2019-09-03 12:38:38'),(218,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 59\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:41',NULL,NULL,NULL,'default','2019-09-03 12:38:38','2019-09-03 12:38:38'),(219,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 70\n',NULL,'2019-09-03 12:38:54',NULL,NULL,NULL,'default','2019-09-03 12:38:39','2019-09-03 12:38:39'),(220,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:42',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:39','2019-09-03 12:38:39'),(221,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 60\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:42',NULL,NULL,NULL,'default','2019-09-03 12:38:39','2019-09-03 12:38:39'),(222,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 71\n',NULL,'2019-09-03 12:38:55',NULL,NULL,NULL,'default','2019-09-03 12:38:40','2019-09-03 12:38:40'),(223,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:43',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:40','2019-09-03 12:38:40'),(224,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 61\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:43',NULL,NULL,NULL,'default','2019-09-03 12:38:40','2019-09-03 12:38:40'),(225,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 72\n',NULL,'2019-09-03 12:38:56',NULL,NULL,NULL,'default','2019-09-03 12:38:41','2019-09-03 12:38:41'),(226,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:44',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:41','2019-09-03 12:38:41'),(227,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 62\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:44',NULL,NULL,NULL,'default','2019-09-03 12:38:41','2019-09-03 12:38:41'),(228,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 73\n',NULL,'2019-09-03 12:38:57',NULL,NULL,NULL,'default','2019-09-03 12:38:42','2019-09-03 12:38:42'),(229,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:45',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:42','2019-09-03 12:38:42'),(230,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 63\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:46',NULL,NULL,NULL,'default','2019-09-03 12:38:43','2019-09-03 12:38:43'),(231,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 74\n',NULL,'2019-09-03 12:38:58',NULL,NULL,NULL,'default','2019-09-03 12:38:43','2019-09-03 12:38:43'),(232,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:46',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:43','2019-09-03 12:38:43'),(233,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 64\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:47',NULL,NULL,NULL,'default','2019-09-03 12:38:44','2019-09-03 12:38:44'),(234,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 75\n',NULL,'2019-09-03 12:39:00',NULL,NULL,NULL,'default','2019-09-03 12:38:45','2019-09-03 12:38:45'),(235,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:48',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:45','2019-09-03 12:38:45'),(236,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 65\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:48',NULL,NULL,NULL,'default','2019-09-03 12:38:45','2019-09-03 12:38:45'),(237,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 76\n',NULL,'2019-09-03 12:39:01',NULL,NULL,NULL,'default','2019-09-03 12:38:46','2019-09-03 12:38:46'),(238,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:49',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:46','2019-09-03 12:38:46'),(239,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 66\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:50',NULL,NULL,NULL,'default','2019-09-03 12:38:47','2019-09-03 12:38:47'),(240,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 77\n',NULL,'2019-09-03 12:39:02',NULL,NULL,NULL,'default','2019-09-03 12:38:47','2019-09-03 12:38:47'),(241,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:50',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:47','2019-09-03 12:38:47'),(242,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 67\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:50',NULL,NULL,NULL,'default','2019-09-03 12:38:47','2019-09-03 12:38:47'),(243,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 78\n',NULL,'2019-09-03 12:39:03',NULL,NULL,NULL,'default','2019-09-03 12:38:48','2019-09-03 12:38:48'),(244,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:51',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:48','2019-09-03 12:38:48'),(245,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 68\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:51',NULL,NULL,NULL,'default','2019-09-03 12:38:48','2019-09-03 12:38:48'),(246,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 79\n',NULL,'2019-09-03 12:39:03',NULL,NULL,NULL,'default','2019-09-03 12:38:48','2019-09-03 12:38:48'),(247,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:52',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:49','2019-09-03 12:38:49'),(248,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 69\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:52',NULL,NULL,NULL,'default','2019-09-03 12:38:49','2019-09-03 12:38:49'),(249,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 80\n',NULL,'2019-09-03 12:39:04',NULL,NULL,NULL,'default','2019-09-03 12:38:49','2019-09-03 12:38:49'),(250,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:52',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:49','2019-09-03 12:38:49'),(251,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 70\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:53',NULL,NULL,NULL,'default','2019-09-03 12:38:50','2019-09-03 12:38:50'),(252,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 81\n',NULL,'2019-09-03 12:39:05',NULL,NULL,NULL,'default','2019-09-03 12:38:50','2019-09-03 12:38:50'),(253,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:53',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:50','2019-09-03 12:38:50'),(254,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 71\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:54',NULL,NULL,NULL,'default','2019-09-03 12:38:51','2019-09-03 12:38:51'),(255,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 82\n',NULL,'2019-09-03 12:39:06',NULL,NULL,NULL,'default','2019-09-03 12:38:51','2019-09-03 12:38:51'),(256,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:54',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:51','2019-09-03 12:38:51'),(257,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 72\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:55',NULL,NULL,NULL,'default','2019-09-03 12:38:52','2019-09-03 12:38:52'),(258,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 83\n',NULL,'2019-09-03 12:39:08',NULL,NULL,NULL,'default','2019-09-03 12:38:53','2019-09-03 12:38:53'),(259,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:56',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:53','2019-09-03 12:38:53'),(260,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 73\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:56',NULL,NULL,NULL,'default','2019-09-03 12:38:53','2019-09-03 12:38:53'),(261,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 84\n',NULL,'2019-09-03 12:39:09',NULL,NULL,NULL,'default','2019-09-03 12:38:54','2019-09-03 12:38:54'),(262,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:57',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:54','2019-09-03 12:38:54'),(263,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 74\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:57',NULL,NULL,NULL,'default','2019-09-03 12:38:54','2019-09-03 12:38:54'),(264,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 85\n',NULL,'2019-09-03 12:39:10',NULL,NULL,NULL,'default','2019-09-03 12:38:55','2019-09-03 12:38:55'),(265,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:58',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:55','2019-09-03 12:38:55'),(266,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 75\nrefresh_dependents: true\n',NULL,'2019-09-03 12:38:59',NULL,NULL,NULL,'default','2019-09-03 12:38:56','2019-09-03 12:38:56'),(267,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 86\n',NULL,'2019-09-03 12:39:11',NULL,NULL,NULL,'default','2019-09-03 12:38:56','2019-09-03 12:38:56'),(268,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:38:59',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:56','2019-09-03 12:38:56'),(269,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 76\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:00',NULL,NULL,NULL,'default','2019-09-03 12:38:57','2019-09-03 12:38:57'),(270,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 87\n',NULL,'2019-09-03 12:39:13',NULL,NULL,NULL,'default','2019-09-03 12:38:58','2019-09-03 12:38:58'),(271,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:01',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:58','2019-09-03 12:38:58'),(272,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 77\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:01',NULL,NULL,NULL,'default','2019-09-03 12:38:58','2019-09-03 12:38:58'),(273,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 88\n',NULL,'2019-09-03 12:39:14',NULL,NULL,NULL,'default','2019-09-03 12:38:59','2019-09-03 12:38:59'),(274,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:02',NULL,NULL,NULL,'authlookup','2019-09-03 12:38:59','2019-09-03 12:38:59'),(275,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 78\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:02',NULL,NULL,NULL,'default','2019-09-03 12:38:59','2019-09-03 12:38:59'),(276,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 89\n',NULL,'2019-09-03 12:39:15',NULL,NULL,NULL,'default','2019-09-03 12:39:00','2019-09-03 12:39:00'),(277,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:03',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:00','2019-09-03 12:39:00'),(278,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 79\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:03',NULL,NULL,NULL,'default','2019-09-03 12:39:00','2019-09-03 12:39:00'),(279,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 90\n',NULL,'2019-09-03 12:39:15',NULL,NULL,NULL,'default','2019-09-03 12:39:00','2019-09-03 12:39:00'),(280,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:04',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:01','2019-09-03 12:39:01'),(281,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 80\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:04',NULL,NULL,NULL,'default','2019-09-03 12:39:01','2019-09-03 12:39:01'),(282,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 91\n',NULL,'2019-09-03 12:39:16',NULL,NULL,NULL,'default','2019-09-03 12:39:01','2019-09-03 12:39:01'),(283,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:04',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:01','2019-09-03 12:39:01'),(284,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 81\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:05',NULL,NULL,NULL,'default','2019-09-03 12:39:02','2019-09-03 12:39:02'),(285,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 92\n',NULL,'2019-09-03 12:39:17',NULL,NULL,NULL,'default','2019-09-03 12:39:02','2019-09-03 12:39:02'),(286,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:05',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:02','2019-09-03 12:39:02'),(287,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 82\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:06',NULL,NULL,NULL,'default','2019-09-03 12:39:03','2019-09-03 12:39:03'),(288,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 93\n',NULL,'2019-09-03 12:39:19',NULL,NULL,NULL,'default','2019-09-03 12:39:04','2019-09-03 12:39:04'),(289,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:07',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:04','2019-09-03 12:39:04'),(290,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 83\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:07',NULL,NULL,NULL,'default','2019-09-03 12:39:04','2019-09-03 12:39:04'),(291,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 94\n',NULL,'2019-09-03 12:39:20',NULL,NULL,NULL,'default','2019-09-03 12:39:05','2019-09-03 12:39:05'),(292,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:08',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:05','2019-09-03 12:39:05'),(293,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 84\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:08',NULL,NULL,NULL,'default','2019-09-03 12:39:05','2019-09-03 12:39:05'),(294,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 95\n',NULL,'2019-09-03 12:39:21',NULL,NULL,NULL,'default','2019-09-03 12:39:06','2019-09-03 12:39:06'),(295,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:09',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:06','2019-09-03 12:39:06'),(296,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 85\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:10',NULL,NULL,NULL,'default','2019-09-03 12:39:07','2019-09-03 12:39:07'),(297,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 96\n',NULL,'2019-09-03 12:39:22',NULL,NULL,NULL,'default','2019-09-03 12:39:07','2019-09-03 12:39:07'),(298,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:10',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:07','2019-09-03 12:39:07'),(299,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 86\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:11',NULL,NULL,NULL,'default','2019-09-03 12:39:08','2019-09-03 12:39:08'),(300,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 97\n',NULL,'2019-09-03 12:39:23',NULL,NULL,NULL,'default','2019-09-03 12:39:09','2019-09-03 12:39:09'),(301,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:12',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:09','2019-09-03 12:39:09'),(302,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 87\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:12',NULL,NULL,NULL,'default','2019-09-03 12:39:09','2019-09-03 12:39:09'),(303,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 98\n',NULL,'2019-09-03 12:39:25',NULL,NULL,NULL,'default','2019-09-03 12:39:10','2019-09-03 12:39:10'),(304,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:13',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:10','2019-09-03 12:39:10'),(305,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 88\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:14',NULL,NULL,NULL,'default','2019-09-03 12:39:11','2019-09-03 12:39:11'),(306,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 99\n',NULL,'2019-09-03 12:39:26',NULL,NULL,NULL,'default','2019-09-03 12:39:11','2019-09-03 12:39:11'),(307,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:14',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:11','2019-09-03 12:39:11'),(308,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 89\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:14',NULL,NULL,NULL,'default','2019-09-03 12:39:11','2019-09-03 12:39:11'),(309,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 100\n',NULL,'2019-09-03 12:39:27',NULL,NULL,NULL,'default','2019-09-03 12:39:12','2019-09-03 12:39:12'),(310,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:15',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:12','2019-09-03 12:39:12'),(311,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 90\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:15',NULL,NULL,NULL,'default','2019-09-03 12:39:12','2019-09-03 12:39:12'),(312,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 101\n',NULL,'2019-09-03 12:39:28',NULL,NULL,NULL,'default','2019-09-03 12:39:13','2019-09-03 12:39:13'),(313,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:16',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:13','2019-09-03 12:39:13'),(314,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 91\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:16',NULL,NULL,NULL,'default','2019-09-03 12:39:13','2019-09-03 12:39:13'),(315,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 102\n',NULL,'2019-09-03 12:39:29',NULL,NULL,NULL,'default','2019-09-03 12:39:14','2019-09-03 12:39:14'),(316,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:17',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:14','2019-09-03 12:39:14'),(317,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 92\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:17',NULL,NULL,NULL,'default','2019-09-03 12:39:14','2019-09-03 12:39:14'),(318,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 103\n',NULL,'2019-09-03 12:39:30',NULL,NULL,NULL,'default','2019-09-03 12:39:15','2019-09-03 12:39:15'),(319,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:18',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:15','2019-09-03 12:39:15'),(320,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 93\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:18',NULL,NULL,NULL,'default','2019-09-03 12:39:15','2019-09-03 12:39:15'),(321,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 104\n',NULL,'2019-09-03 12:39:31',NULL,NULL,NULL,'default','2019-09-03 12:39:16','2019-09-03 12:39:16'),(322,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:19',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:16','2019-09-03 12:39:16'),(323,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 94\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:19',NULL,NULL,NULL,'default','2019-09-03 12:39:16','2019-09-03 12:39:16'),(324,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 105\n',NULL,'2019-09-03 12:39:32',NULL,NULL,NULL,'default','2019-09-03 12:39:17','2019-09-03 12:39:17'),(325,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:20',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:17','2019-09-03 12:39:17'),(326,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 95\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:20',NULL,NULL,NULL,'default','2019-09-03 12:39:17','2019-09-03 12:39:17'),(327,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 106\n',NULL,'2019-09-03 12:39:33',NULL,NULL,NULL,'default','2019-09-03 12:39:18','2019-09-03 12:39:18'),(328,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:21',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:18','2019-09-03 12:39:18'),(329,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 96\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:21',NULL,NULL,NULL,'default','2019-09-03 12:39:18','2019-09-03 12:39:18'),(330,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 107\n',NULL,'2019-09-03 12:39:34',NULL,NULL,NULL,'default','2019-09-03 12:39:19','2019-09-03 12:39:19'),(331,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:22',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:19','2019-09-03 12:39:19'),(332,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 97\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:23',NULL,NULL,NULL,'default','2019-09-03 12:39:20','2019-09-03 12:39:20'),(333,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 108\n',NULL,'2019-09-03 12:39:35',NULL,NULL,NULL,'default','2019-09-03 12:39:20','2019-09-03 12:39:20'),(334,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:23',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:20','2019-09-03 12:39:20'),(335,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 98\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:24',NULL,NULL,NULL,'default','2019-09-03 12:39:21','2019-09-03 12:39:21'),(336,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 109\n',NULL,'2019-09-03 12:39:37',NULL,NULL,NULL,'default','2019-09-03 12:39:22','2019-09-03 12:39:22'),(337,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:25',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:22','2019-09-03 12:39:22'),(338,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 99\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:26',NULL,NULL,NULL,'default','2019-09-03 12:39:23','2019-09-03 12:39:23'),(339,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 110\n',NULL,'2019-09-03 12:39:38',NULL,NULL,NULL,'default','2019-09-03 12:39:23','2019-09-03 12:39:23'),(340,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:26',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:23','2019-09-03 12:39:23'),(341,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 100\nrefresh_dependents: true\n',NULL,'2019-09-03 12:39:27',NULL,NULL,NULL,'default','2019-09-03 12:39:24','2019-09-03 12:39:24'),(342,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 111\n',NULL,'2019-09-03 12:39:40',NULL,NULL,NULL,'default','2019-09-03 12:39:25','2019-09-03 12:39:25'),(343,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2019-09-03 12:39:28',NULL,NULL,NULL,'authlookup','2019-09-03 12:39:25','2019-09-03 12:39:25');
/*!40000 ALTER TABLE `delayed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `disciplines`
--

DROP TABLE IF EXISTS `disciplines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `disciplines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `disciplines`
--

LOCK TABLES `disciplines` WRITE;
/*!40000 ALTER TABLE `disciplines` DISABLE KEYS */;
INSERT INTO `disciplines` VALUES (1,'Modeller','2019-09-03 12:32:48','2019-09-03 12:32:48'),(2,'Experimentalist','2019-09-03 12:32:48','2019-09-03 12:32:48'),(3,'Bioinformatician','2019-09-03 12:32:48','2019-09-03 12:32:48');
/*!40000 ALTER TABLE `disciplines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `disciplines_people`
--

DROP TABLE IF EXISTS `disciplines_people`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `disciplines_people` (
  `discipline_id` int(11) DEFAULT NULL,
  `person_id` int(11) DEFAULT NULL,
  KEY `index_disciplines_people_on_person_id` (`person_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `disciplines_people`
--

LOCK TABLES `disciplines_people` WRITE;
/*!40000 ALTER TABLE `disciplines_people` DISABLE KEYS */;
/*!40000 ALTER TABLE `disciplines_people` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_auth_lookup`
--

DROP TABLE IF EXISTS `document_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_auth_lookup` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_document_user_id_asset_id_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_document_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_auth_lookup`
--

LOCK TABLES `document_auth_lookup` WRITE;
/*!40000 ALTER TABLE `document_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `document_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_versions`
--

DROP TABLE IF EXISTS `document_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `document_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `revision_comments` text,
  `title` text,
  `description` text,
  `contributor_id` int(11) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `other_creators` text,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_document_versions_on_contributor` (`contributor_id`),
  KEY `index_document_versions_on_document_id` (`document_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_versions`
--

LOCK TABLES `document_versions` WRITE;
/*!40000 ALTER TABLE `document_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `document_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_versions_projects`
--

DROP TABLE IF EXISTS `document_versions_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_versions_projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `version_id` int(11) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_document_versions_projects_on_project_id` (`project_id`),
  KEY `index_document_versions_projects_on_version_id_and_project_id` (`version_id`,`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_versions_projects`
--

LOCK TABLES `document_versions_projects` WRITE;
/*!40000 ALTER TABLE `document_versions_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `document_versions_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` text,
  `description` text,
  `contributor_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `other_creators` text,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_documents_on_contributor` (`contributor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documents`
--

LOCK TABLES `documents` WRITE;
/*!40000 ALTER TABLE `documents` DISABLE KEYS */;
/*!40000 ALTER TABLE `documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documents_events`
--

DROP TABLE IF EXISTS `documents_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents_events` (
  `document_id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  KEY `index_documents_events_on_document_id_and_event_id` (`document_id`,`event_id`),
  KEY `index_documents_events_on_event_id_and_document_id` (`event_id`,`document_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documents_events`
--

LOCK TABLES `documents_events` WRITE;
/*!40000 ALTER TABLE `documents_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `documents_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documents_projects`
--

DROP TABLE IF EXISTS `documents_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents_projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `document_id` int(11) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_documents_projects_on_document_id_and_project_id` (`document_id`,`project_id`),
  KEY `index_documents_projects_on_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documents_projects`
--

LOCK TABLES `documents_projects` WRITE;
/*!40000 ALTER TABLE `documents_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `documents_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_auth_lookup`
--

DROP TABLE IF EXISTS `event_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_event_auth_lookup_on_user_id_and_asset_id_and_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_event_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_auth_lookup`
--

LOCK TABLES `event_auth_lookup` WRITE;
/*!40000 ALTER TABLE `event_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `address` text,
  `city` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `description` text,
  `title` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events_presentations`
--

DROP TABLE IF EXISTS `events_presentations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events_presentations` (
  `presentation_id` int(11) DEFAULT NULL,
  `event_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events_presentations`
--

LOCK TABLES `events_presentations` WRITE;
/*!40000 ALTER TABLE `events_presentations` DISABLE KEYS */;
/*!40000 ALTER TABLE `events_presentations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events_projects`
--

DROP TABLE IF EXISTS `events_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events_projects` (
  `project_id` int(11) DEFAULT NULL,
  `event_id` int(11) DEFAULT NULL,
  KEY `index_events_projects_on_event_id_and_project_id` (`event_id`,`project_id`),
  KEY `index_events_projects_on_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events_projects`
--

LOCK TABLES `events_projects` WRITE;
/*!40000 ALTER TABLE `events_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `events_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events_publications`
--

DROP TABLE IF EXISTS `events_publications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events_publications` (
  `publication_id` int(11) DEFAULT NULL,
  `event_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events_publications`
--

LOCK TABLES `events_publications` WRITE;
/*!40000 ALTER TABLE `events_publications` DISABLE KEYS */;
/*!40000 ALTER TABLE `events_publications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `experimental_condition_links`
--

DROP TABLE IF EXISTS `experimental_condition_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `experimental_condition_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `substance_type` varchar(255) DEFAULT NULL,
  `substance_id` int(11) DEFAULT NULL,
  `experimental_condition_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `experimental_condition_links`
--

LOCK TABLES `experimental_condition_links` WRITE;
/*!40000 ALTER TABLE `experimental_condition_links` DISABLE KEYS */;
/*!40000 ALTER TABLE `experimental_condition_links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `experimental_conditions`
--

DROP TABLE IF EXISTS `experimental_conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `experimental_conditions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `measured_item_id` int(11) DEFAULT NULL,
  `start_value` float DEFAULT NULL,
  `end_value` float DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `sop_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `sop_version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_experimental_conditions_on_sop_id` (`sop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `experimental_conditions`
--

LOCK TABLES `experimental_conditions` WRITE;
/*!40000 ALTER TABLE `experimental_conditions` DISABLE KEYS */;
/*!40000 ALTER TABLE `experimental_conditions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `external_assets`
--

DROP TABLE IF EXISTS `external_assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `external_assets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `external_service` varchar(255) NOT NULL,
  `external_id` varchar(255) NOT NULL,
  `external_mod_stamp` varchar(255) DEFAULT NULL,
  `external_type` varchar(255) DEFAULT NULL,
  `synchronized_at` datetime DEFAULT NULL,
  `sync_state` tinyint(4) NOT NULL DEFAULT '0',
  `sync_options_json` text,
  `version` int(11) NOT NULL DEFAULT '0',
  `seek_entity_id` int(11) DEFAULT NULL,
  `seek_entity_type` varchar(255) DEFAULT NULL,
  `seek_service_id` int(11) DEFAULT NULL,
  `seek_service_type` varchar(255) DEFAULT NULL,
  `class_type` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `err_msg` varchar(255) DEFAULT NULL,
  `failures` int(11) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_external_assets_on_seek_entity_type_and_seek_entity_id` (`seek_entity_type`,`seek_entity_id`),
  KEY `index_external_assets_on_seek_service_type_and_seek_service_id` (`seek_service_type`,`seek_service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `external_assets`
--

LOCK TABLES `external_assets` WRITE;
/*!40000 ALTER TABLE `external_assets` DISABLE KEYS */;
/*!40000 ALTER TABLE `external_assets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `favourite_group_memberships`
--

DROP TABLE IF EXISTS `favourite_group_memberships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favourite_group_memberships` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) DEFAULT NULL,
  `favourite_group_id` int(11) DEFAULT NULL,
  `access_type` tinyint(4) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `favourite_group_memberships`
--

LOCK TABLES `favourite_group_memberships` WRITE;
/*!40000 ALTER TABLE `favourite_group_memberships` DISABLE KEYS */;
/*!40000 ALTER TABLE `favourite_group_memberships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `favourite_groups`
--

DROP TABLE IF EXISTS `favourite_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favourite_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `favourite_groups`
--

LOCK TABLES `favourite_groups` WRITE;
/*!40000 ALTER TABLE `favourite_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `favourite_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `favourites`
--

DROP TABLE IF EXISTS `favourites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favourites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `resource_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `resource_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `favourites`
--

LOCK TABLES `favourites` WRITE;
/*!40000 ALTER TABLE `favourites` DISABLE KEYS */;
/*!40000 ALTER TABLE `favourites` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `genes`
--

DROP TABLE IF EXISTS `genes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `genes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `symbol` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `genes`
--

LOCK TABLES `genes` WRITE;
/*!40000 ALTER TABLE `genes` DISABLE KEYS */;
/*!40000 ALTER TABLE `genes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `genotypes`
--

DROP TABLE IF EXISTS `genotypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `genotypes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gene_id` int(11) DEFAULT NULL,
  `modification_id` int(11) DEFAULT NULL,
  `strain_id` int(11) DEFAULT NULL,
  `comment` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `genotypes`
--

LOCK TABLES `genotypes` WRITE;
/*!40000 ALTER TABLE `genotypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `genotypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group_memberships`
--

DROP TABLE IF EXISTS `group_memberships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `group_memberships` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) DEFAULT NULL,
  `work_group_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `time_left_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_group_memberships_on_person_id` (`person_id`),
  KEY `index_group_memberships_on_work_group_id_and_person_id` (`work_group_id`,`person_id`),
  KEY `index_group_memberships_on_work_group_id` (`work_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_memberships`
--

LOCK TABLES `group_memberships` WRITE;
/*!40000 ALTER TABLE `group_memberships` DISABLE KEYS */;
INSERT INTO `group_memberships` VALUES (1,1,2,'2019-09-03 12:33:33','2019-09-03 12:33:33',NULL),(2,1,1,'2019-09-03 12:33:33','2019-09-03 12:33:33',NULL),(3,1,3,'2019-09-03 12:36:26','2019-09-03 12:36:26',NULL),(4,1,4,'2019-09-03 12:36:26','2019-09-03 12:36:26',NULL),(5,1,5,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL),(6,1,6,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL),(7,1,7,'2019-09-03 12:36:27','2019-09-03 12:36:27',NULL),(8,1,8,'2019-09-03 12:36:28','2019-09-03 12:36:28',NULL),(9,1,9,'2019-09-03 12:36:28','2019-09-03 12:36:28',NULL),(10,1,10,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL),(11,1,11,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL),(12,1,12,'2019-09-03 12:36:29','2019-09-03 12:36:29',NULL),(13,2,3,'2019-09-03 12:37:39','2019-09-03 12:37:39',NULL),(14,3,3,'2019-09-03 12:37:40','2019-09-03 12:37:40',NULL),(15,4,3,'2019-09-03 12:37:41','2019-09-03 12:37:41',NULL),(16,5,3,'2019-09-03 12:37:42','2019-09-03 12:37:42',NULL),(17,6,3,'2019-09-03 12:37:43','2019-09-03 12:37:43',NULL),(18,7,3,'2019-09-03 12:37:44','2019-09-03 12:37:44',NULL),(19,8,4,'2019-09-03 12:37:44','2019-09-03 12:37:44',NULL),(20,9,5,'2019-09-03 12:37:45','2019-09-03 12:37:45',NULL),(21,10,5,'2019-09-03 12:37:46','2019-09-03 12:37:46',NULL),(22,11,5,'2019-09-03 12:37:47','2019-09-03 12:37:47',NULL),(23,12,5,'2019-09-03 12:37:47','2019-09-03 12:37:47',NULL),(24,13,5,'2019-09-03 12:37:48','2019-09-03 12:37:48',NULL),(25,14,5,'2019-09-03 12:37:50','2019-09-03 12:37:50',NULL),(26,15,5,'2019-09-03 12:37:51','2019-09-03 12:37:51',NULL),(27,16,5,'2019-09-03 12:37:52','2019-09-03 12:37:52',NULL),(28,17,6,'2019-09-03 12:37:53','2019-09-03 12:37:53',NULL),(29,18,6,'2019-09-03 12:37:53','2019-09-03 12:37:53',NULL),(30,19,6,'2019-09-03 12:37:54','2019-09-03 12:37:54',NULL),(31,20,6,'2019-09-03 12:37:55','2019-09-03 12:37:55',NULL),(32,21,6,'2019-09-03 12:37:56','2019-09-03 12:37:56',NULL),(33,22,6,'2019-09-03 12:37:57','2019-09-03 12:37:57',NULL),(34,23,7,'2019-09-03 12:37:58','2019-09-03 12:37:58',NULL),(35,24,7,'2019-09-03 12:37:59','2019-09-03 12:37:59',NULL),(36,25,7,'2019-09-03 12:38:00','2019-09-03 12:38:00',NULL),(37,26,7,'2019-09-03 12:38:01','2019-09-03 12:38:01',NULL),(38,27,7,'2019-09-03 12:38:01','2019-09-03 12:38:01',NULL),(39,28,7,'2019-09-03 12:38:03','2019-09-03 12:38:03',NULL),(40,29,7,'2019-09-03 12:38:04','2019-09-03 12:38:04',NULL),(41,30,7,'2019-09-03 12:38:05','2019-09-03 12:38:05',NULL),(42,31,8,'2019-09-03 12:38:06','2019-09-03 12:38:06',NULL),(43,32,8,'2019-09-03 12:38:07','2019-09-03 12:38:07',NULL),(44,33,8,'2019-09-03 12:38:08','2019-09-03 12:38:08',NULL),(45,34,8,'2019-09-03 12:38:08','2019-09-03 12:38:08',NULL),(46,35,8,'2019-09-03 12:38:09','2019-09-03 12:38:09',NULL),(47,36,8,'2019-09-03 12:38:10','2019-09-03 12:38:10',NULL),(48,37,8,'2019-09-03 12:38:11','2019-09-03 12:38:11',NULL),(49,38,9,'2019-09-03 12:38:12','2019-09-03 12:38:12',NULL),(50,39,9,'2019-09-03 12:38:13','2019-09-03 12:38:13',NULL),(51,40,9,'2019-09-03 12:38:14','2019-09-03 12:38:14',NULL),(52,41,9,'2019-09-03 12:38:15','2019-09-03 12:38:15',NULL),(53,42,9,'2019-09-03 12:38:16','2019-09-03 12:38:16',NULL),(54,43,9,'2019-09-03 12:38:17','2019-09-03 12:38:17',NULL),(55,44,9,'2019-09-03 12:38:18','2019-09-03 12:38:18',NULL),(56,45,9,'2019-09-03 12:38:19','2019-09-03 12:38:19',NULL),(57,46,9,'2019-09-03 12:38:20','2019-09-03 12:38:20',NULL),(58,47,9,'2019-09-03 12:38:22','2019-09-03 12:38:22',NULL),(59,48,9,'2019-09-03 12:38:23','2019-09-03 12:38:23',NULL),(60,49,9,'2019-09-03 12:38:24','2019-09-03 12:38:24',NULL),(61,50,9,'2019-09-03 12:38:26','2019-09-03 12:38:26',NULL),(62,51,9,'2019-09-03 12:38:28','2019-09-03 12:38:28',NULL),(63,52,9,'2019-09-03 12:38:29','2019-09-03 12:38:29',NULL),(64,53,9,'2019-09-03 12:38:31','2019-09-03 12:38:31',NULL),(65,54,9,'2019-09-03 12:38:33','2019-09-03 12:38:33',NULL),(66,55,9,'2019-09-03 12:38:35','2019-09-03 12:38:35',NULL),(67,56,10,'2019-09-03 12:38:36','2019-09-03 12:38:36',NULL),(68,57,10,'2019-09-03 12:38:37','2019-09-03 12:38:37',NULL),(69,58,10,'2019-09-03 12:38:38','2019-09-03 12:38:38',NULL),(70,59,10,'2019-09-03 12:38:39','2019-09-03 12:38:39',NULL),(71,60,10,'2019-09-03 12:38:40','2019-09-03 12:38:40',NULL),(72,61,10,'2019-09-03 12:38:41','2019-09-03 12:38:41',NULL),(73,62,10,'2019-09-03 12:38:42','2019-09-03 12:38:42',NULL),(74,63,10,'2019-09-03 12:38:43','2019-09-03 12:38:43',NULL),(75,64,10,'2019-09-03 12:38:45','2019-09-03 12:38:45',NULL),(76,65,10,'2019-09-03 12:38:46','2019-09-03 12:38:46',NULL),(77,66,11,'2019-09-03 12:38:47','2019-09-03 12:38:47',NULL),(78,67,11,'2019-09-03 12:38:48','2019-09-03 12:38:48',NULL),(79,68,11,'2019-09-03 12:38:48','2019-09-03 12:38:48',NULL),(80,69,11,'2019-09-03 12:38:49','2019-09-03 12:38:49',NULL),(81,70,11,'2019-09-03 12:38:50','2019-09-03 12:38:50',NULL),(82,71,11,'2019-09-03 12:38:51','2019-09-03 12:38:51',NULL),(83,72,11,'2019-09-03 12:38:53','2019-09-03 12:38:53',NULL),(84,73,11,'2019-09-03 12:38:54','2019-09-03 12:38:54',NULL),(85,74,11,'2019-09-03 12:38:55','2019-09-03 12:38:55',NULL),(86,75,11,'2019-09-03 12:38:56','2019-09-03 12:38:56',NULL),(87,76,11,'2019-09-03 12:38:58','2019-09-03 12:38:58',NULL),(88,77,12,'2019-09-03 12:38:59','2019-09-03 12:38:59',NULL),(89,78,12,'2019-09-03 12:39:00','2019-09-03 12:39:00',NULL),(90,79,12,'2019-09-03 12:39:00','2019-09-03 12:39:00',NULL),(91,80,12,'2019-09-03 12:39:01','2019-09-03 12:39:01',NULL),(92,81,12,'2019-09-03 12:39:02','2019-09-03 12:39:02',NULL),(93,82,12,'2019-09-03 12:39:04','2019-09-03 12:39:04',NULL),(94,83,12,'2019-09-03 12:39:05','2019-09-03 12:39:05',NULL),(95,84,12,'2019-09-03 12:39:06','2019-09-03 12:39:06',NULL),(96,85,12,'2019-09-03 12:39:07','2019-09-03 12:39:07',NULL),(97,86,12,'2019-09-03 12:39:08','2019-09-03 12:39:08',NULL),(98,87,12,'2019-09-03 12:39:10','2019-09-03 12:39:10',NULL),(99,88,2,'2019-09-03 12:39:11','2019-09-03 12:39:11',NULL),(100,89,2,'2019-09-03 12:39:12','2019-09-03 12:39:12',NULL),(101,90,2,'2019-09-03 12:39:13','2019-09-03 12:39:13',NULL),(102,91,2,'2019-09-03 12:39:14','2019-09-03 12:39:14',NULL),(103,92,2,'2019-09-03 12:39:15','2019-09-03 12:39:15',NULL),(104,93,2,'2019-09-03 12:39:16','2019-09-03 12:39:16',NULL),(105,94,2,'2019-09-03 12:39:17','2019-09-03 12:39:17',NULL),(106,95,2,'2019-09-03 12:39:18','2019-09-03 12:39:18',NULL),(107,96,2,'2019-09-03 12:39:19','2019-09-03 12:39:19',NULL),(108,97,2,'2019-09-03 12:39:20','2019-09-03 12:39:20',NULL),(109,98,2,'2019-09-03 12:39:22','2019-09-03 12:39:22',NULL),(110,99,2,'2019-09-03 12:39:23','2019-09-03 12:39:23',NULL),(111,100,2,'2019-09-03 12:39:25','2019-09-03 12:39:25',NULL);
/*!40000 ALTER TABLE `group_memberships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `group_memberships_project_positions`
--

DROP TABLE IF EXISTS `group_memberships_project_positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `group_memberships_project_positions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_membership_id` int(11) DEFAULT NULL,
  `project_position_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_memberships_project_positions`
--

LOCK TABLES `group_memberships_project_positions` WRITE;
/*!40000 ALTER TABLE `group_memberships_project_positions` DISABLE KEYS */;
/*!40000 ALTER TABLE `group_memberships_project_positions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `help_attachments`
--

DROP TABLE IF EXISTS `help_attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `help_attachments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `help_document_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `content_type` varchar(255) DEFAULT NULL,
  `filename` varchar(255) DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `db_file_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `help_attachments`
--

LOCK TABLES `help_attachments` WRITE;
/*!40000 ALTER TABLE `help_attachments` DISABLE KEYS */;
/*!40000 ALTER TABLE `help_attachments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `help_documents`
--

DROP TABLE IF EXISTS `help_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `help_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `body` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `help_documents`
--

LOCK TABLES `help_documents` WRITE;
/*!40000 ALTER TABLE `help_documents` DISABLE KEYS */;
/*!40000 ALTER TABLE `help_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `help_images`
--

DROP TABLE IF EXISTS `help_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `help_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `help_document_id` int(11) DEFAULT NULL,
  `content_type` varchar(255) DEFAULT NULL,
  `filename` varchar(255) DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `width` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `thumbnail` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `help_images`
--

LOCK TABLES `help_images` WRITE;
/*!40000 ALTER TABLE `help_images` DISABLE KEYS */;
/*!40000 ALTER TABLE `help_images` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `institutions`
--

DROP TABLE IF EXISTS `institutions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `institutions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `address` text,
  `city` varchar(255) DEFAULT NULL,
  `web_page` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `avatar_id` int(11) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `institutions`
--

LOCK TABLES `institutions` WRITE;
/*!40000 ALTER TABLE `institutions` DISABLE KEYS */;
INSERT INTO `institutions` VALUES (1,'Default Institution',NULL,NULL,NULL,'United Kingdom','2019-09-03 12:32:52','2019-09-03 12:32:52',NULL,'D','dee808b0-b074-0137-134a-721898481898'),(2,'Heidelberg Institute for Theoretical Studies',NULL,'Heidelberg','http://www.h-its.org/','Germany','2019-09-03 12:33:32','2019-09-03 12:33:32',NULL,'H','f70bdc60-b074-0137-134b-721898481898');
/*!40000 ALTER TABLE `institutions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `investigation_auth_lookup`
--

DROP TABLE IF EXISTS `investigation_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `investigation_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_inv_user_id_asset_id_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_investigation_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `investigation_auth_lookup`
--

LOCK TABLES `investigation_auth_lookup` WRITE;
/*!40000 ALTER TABLE `investigation_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `investigation_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `investigations`
--

DROP TABLE IF EXISTS `investigations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `investigations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `other_creators` text,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `investigations`
--

LOCK TABLES `investigations` WRITE;
/*!40000 ALTER TABLE `investigations` DISABLE KEYS */;
/*!40000 ALTER TABLE `investigations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `investigations_projects`
--

DROP TABLE IF EXISTS `investigations_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `investigations_projects` (
  `project_id` int(11) DEFAULT NULL,
  `investigation_id` int(11) DEFAULT NULL,
  KEY `index_investigations_projects_inv_proj_id` (`investigation_id`,`project_id`),
  KEY `index_investigations_projects_on_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `investigations_projects`
--

LOCK TABLES `investigations_projects` WRITE;
/*!40000 ALTER TABLE `investigations_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `investigations_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mapping_links`
--

DROP TABLE IF EXISTS `mapping_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mapping_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `substance_type` varchar(255) DEFAULT NULL,
  `substance_id` int(11) DEFAULT NULL,
  `mapping_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=860 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mapping_links`
--

LOCK TABLES `mapping_links` WRITE;
/*!40000 ALTER TABLE `mapping_links` DISABLE KEYS */;
INSERT INTO `mapping_links` VALUES (117,'Compound',125,105,'2011-09-09 09:27:51','2011-09-09 09:27:51'),(118,'Compound',125,106,'2011-09-09 09:27:51','2011-09-09 09:27:51'),(119,'Compound',125,107,'2011-09-09 09:27:51','2011-09-09 09:27:51'),(120,'Compound',125,108,'2011-09-09 09:27:51','2011-09-09 09:27:51'),(121,'Compound',125,109,'2011-09-09 09:27:51','2011-09-09 09:27:51'),(122,'Compound',125,110,'2011-09-09 09:27:51','2011-09-09 09:27:51'),(125,'Compound',29,113,'2011-09-12 14:07:33','2011-09-12 14:07:33'),(131,'Compound',102,114,'2011-09-12 14:32:14','2011-09-12 14:32:14'),(501,'Compound',40,14,'2012-12-20 12:52:45','2012-12-20 12:52:45'),(502,'Compound',40,13,'2012-12-20 12:52:45','2012-12-20 12:52:45'),(520,'Compound',48,113,'2012-12-20 12:52:47','2012-12-20 12:52:47'),(525,'Compound',49,171,'2012-12-20 12:52:47','2012-12-20 12:52:47'),(526,'Compound',50,23,'2012-12-20 12:52:47','2012-12-20 12:52:47'),(527,'Compound',50,22,'2012-12-20 12:52:47','2012-12-20 12:52:47'),(529,'Compound',53,172,'2012-12-20 12:52:47','2012-12-20 12:52:47'),(530,'Compound',54,26,'2012-12-20 12:52:47','2012-12-20 12:52:47'),(533,'Compound',1,4,'2012-12-20 12:52:48','2012-12-20 12:52:48'),(534,'Compound',1,3,'2012-12-20 12:52:48','2012-12-20 12:52:48'),(535,'Compound',55,27,'2012-12-20 12:52:48','2012-12-20 12:52:48'),(536,'Compound',56,29,'2012-12-20 12:52:48','2012-12-20 12:52:48'),(537,'Compound',56,30,'2012-12-20 12:52:48','2012-12-20 12:52:48'),(538,'Compound',56,28,'2012-12-20 12:52:48','2012-12-20 12:52:48'),(539,'Compound',57,31,'2012-12-20 12:52:48','2012-12-20 12:52:48'),(548,'Compound',58,32,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(549,'Compound',2,120,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(550,'Compound',2,118,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(551,'Compound',2,119,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(554,'Compound',60,35,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(555,'Compound',61,36,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(556,'Compound',62,173,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(559,'Compound',63,37,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(560,'Compound',3,121,'2012-12-20 12:52:49','2012-12-20 12:52:49'),(561,'Compound',59,33,'2012-12-20 12:52:50','2012-12-20 12:52:50'),(562,'Compound',59,34,'2012-12-20 12:52:50','2012-12-20 12:52:50'),(565,'Compound',64,38,'2012-12-20 12:52:50','2012-12-20 12:52:50'),(566,'Compound',65,39,'2012-12-20 12:52:50','2012-12-20 12:52:50'),(568,'Compound',66,40,'2012-12-20 12:52:50','2012-12-20 12:52:50'),(579,'Compound',70,43,'2012-12-20 12:52:51','2012-12-20 12:52:51'),(580,'Compound',70,44,'2012-12-20 12:52:51','2012-12-20 12:52:51'),(581,'Compound',5,122,'2012-12-20 12:52:51','2012-12-20 12:52:51'),(584,'Compound',6,124,'2012-12-20 12:52:51','2012-12-20 12:52:51'),(585,'Compound',6,123,'2012-12-20 12:52:51','2012-12-20 12:52:51'),(590,'Compound',68,42,'2012-12-20 12:52:51','2012-12-20 12:52:51'),(591,'Compound',68,41,'2012-12-20 12:52:51','2012-12-20 12:52:51'),(592,'Compound',71,45,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(593,'Compound',71,46,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(594,'Compound',37,11,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(597,'Compound',38,12,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(598,'Compound',72,47,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(599,'Compound',72,48,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(602,'Compound',74,51,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(603,'Compound',74,52,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(604,'Compound',75,54,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(605,'Compound',75,53,'2012-12-20 12:52:52','2012-12-20 12:52:52'),(613,'Compound',78,56,'2012-12-20 12:52:53','2012-12-20 12:52:53'),(614,'Compound',78,57,'2012-12-20 12:52:53','2012-12-20 12:52:53'),(615,'Compound',79,59,'2012-12-20 12:52:53','2012-12-20 12:52:53'),(616,'Compound',79,58,'2012-12-20 12:52:53','2012-12-20 12:52:53'),(618,'Compound',52,24,'2012-12-20 12:52:54','2012-12-20 12:52:54'),(619,'Compound',73,50,'2012-12-20 12:52:54','2012-12-20 12:52:54'),(620,'Compound',73,49,'2012-12-20 12:52:54','2012-12-20 12:52:54'),(624,'Compound',82,64,'2012-12-20 12:52:54','2012-12-20 12:52:54'),(628,'Compound',46,21,'2012-12-20 12:52:55','2012-12-20 12:52:55'),(645,'Compound',88,68,'2012-12-20 12:52:55','2012-12-20 12:52:55'),(646,'Compound',89,69,'2012-12-20 12:52:55','2012-12-20 12:52:55'),(647,'Compound',90,174,'2012-12-20 12:52:56','2012-12-20 12:52:56'),(648,'Compound',91,71,'2012-12-20 12:52:56','2012-12-20 12:52:56'),(652,'Compound',92,73,'2012-12-20 12:52:56','2012-12-20 12:52:56'),(653,'Compound',92,72,'2012-12-20 12:52:56','2012-12-20 12:52:56'),(656,'Compound',94,74,'2012-12-20 12:52:56','2012-12-20 12:52:56'),(657,'Compound',94,75,'2012-12-20 12:52:56','2012-12-20 12:52:56'),(660,'Compound',83,65,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(661,'Compound',81,62,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(662,'Compound',81,61,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(663,'Compound',81,63,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(666,'Compound',80,60,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(667,'Compound',8,112,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(668,'Compound',8,111,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(670,'Compound',9,137,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(671,'Compound',9,135,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(672,'Compound',9,136,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(673,'Compound',9,134,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(674,'Compound',9,132,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(675,'Compound',9,133,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(676,'Compound',32,175,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(677,'Compound',42,16,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(678,'Compound',42,15,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(679,'Compound',45,19,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(680,'Compound',45,20,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(681,'Compound',98,78,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(682,'Compound',84,66,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(683,'Compound',10,140,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(684,'Compound',10,139,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(688,'Compound',99,80,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(689,'Compound',99,79,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(690,'Compound',95,76,'2012-12-20 12:52:58','2012-12-20 12:52:58'),(693,'Compound',11,142,'2012-12-20 12:52:59','2012-12-20 12:52:59'),(694,'Compound',11,141,'2012-12-20 12:52:59','2012-12-20 12:52:59'),(695,'Compound',100,114,'2012-12-20 12:52:59','2012-12-20 12:52:59'),(697,'Compound',104,176,'2012-12-20 12:52:59','2012-12-20 12:52:59'),(700,'Compound',103,82,'2012-12-20 12:52:59','2012-12-20 12:52:59'),(706,'Compound',106,84,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(707,'Compound',106,85,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(708,'Compound',106,86,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(709,'Compound',105,83,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(713,'Compound',13,5,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(714,'Compound',13,7,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(715,'Compound',13,6,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(716,'Compound',14,144,'2012-12-20 12:53:00','2012-12-20 12:53:00'),(717,'Compound',14,143,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(718,'Compound',107,87,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(719,'Compound',107,88,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(720,'Compound',15,145,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(721,'Compound',108,89,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(722,'Compound',108,90,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(723,'Compound',108,91,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(724,'Compound',108,92,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(725,'Compound',16,147,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(726,'Compound',16,146,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(727,'Compound',16,149,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(728,'Compound',16,148,'2012-12-20 12:53:01','2012-12-20 12:53:01'),(741,'Compound',87,67,'2012-12-20 12:53:02','2012-12-20 12:53:02'),(761,'Compound',76,55,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(762,'Compound',17,150,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(763,'Compound',110,129,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(764,'Compound',110,128,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(765,'Compound',110,130,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(766,'Compound',110,126,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(767,'Compound',110,125,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(768,'Compound',110,127,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(775,'Compound',18,152,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(776,'Compound',18,151,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(777,'Compound',18,154,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(778,'Compound',18,153,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(779,'Compound',19,177,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(780,'Compound',19,178,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(781,'Compound',19,179,'2012-12-20 12:53:03','2012-12-20 12:53:03'),(787,'Compound',117,98,'2012-12-20 12:53:04','2012-12-20 12:53:04'),(788,'Compound',117,97,'2012-12-20 12:53:04','2012-12-20 12:53:04'),(791,'Compound',20,156,'2012-12-20 12:53:04','2012-12-20 12:53:04'),(792,'Compound',20,155,'2012-12-20 12:53:04','2012-12-20 12:53:04'),(798,'Compound',44,17,'2012-12-20 12:53:05','2012-12-20 12:53:05'),(799,'Compound',44,18,'2012-12-20 12:53:05','2012-12-20 12:53:05'),(803,'Compound',116,94,'2012-12-20 12:53:07','2012-12-20 12:53:07'),(804,'Compound',116,95,'2012-12-20 12:53:07','2012-12-20 12:53:07'),(805,'Compound',116,96,'2012-12-20 12:53:07','2012-12-20 12:53:07'),(806,'Compound',21,157,'2012-12-20 12:53:07','2012-12-20 12:53:07'),(811,'Compound',22,1,'2012-12-20 12:53:07','2012-12-20 12:53:07'),(812,'Compound',22,2,'2012-12-20 12:53:07','2012-12-20 12:53:07'),(813,'Compound',96,77,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(814,'Compound',23,161,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(815,'Compound',23,160,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(816,'Compound',23,159,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(817,'Compound',23,158,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(820,'Compound',24,9,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(821,'Compound',24,8,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(822,'Compound',121,99,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(823,'Compound',25,180,'2012-12-20 12:53:08','2012-12-20 12:53:08'),(836,'Compound',114,93,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(837,'Compound',124,100,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(838,'Compound',124,101,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(839,'Compound',113,105,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(840,'Compound',113,106,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(841,'Compound',113,107,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(842,'Compound',113,108,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(843,'Compound',113,109,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(844,'Compound',113,110,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(845,'Compound',26,165,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(846,'Compound',26,166,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(847,'Compound',26,163,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(848,'Compound',26,164,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(850,'Compound',128,102,'2012-12-20 12:53:09','2012-12-20 12:53:09'),(855,'Compound',129,103,'2012-12-20 12:53:10','2012-12-20 12:53:10'),(856,'Compound',129,104,'2012-12-20 12:53:10','2012-12-20 12:53:10'),(857,'Compound',27,168,'2012-12-20 12:53:10','2012-12-20 12:53:10'),(858,'Compound',27,167,'2012-12-20 12:53:10','2012-12-20 12:53:10'),(859,'Compound',101,81,'2012-12-20 12:53:10','2012-12-20 12:53:10');
/*!40000 ALTER TABLE `mapping_links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mappings`
--

DROP TABLE IF EXISTS `mappings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mappings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sabiork_id` int(11) DEFAULT NULL,
  `chebi_id` varchar(255) DEFAULT NULL,
  `kegg_id` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=181 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mappings`
--

LOCK TABLES `mappings` WRITE;
/*!40000 ALTER TABLE `mappings` DISABLE KEYS */;
INSERT INTO `mappings` VALUES (1,33,'32816','C00022','2011-08-25 16:28:53','2011-08-25 16:28:53'),(2,33,'15361','C00022','2011-08-25 16:28:53','2011-08-25 16:28:53'),(3,1278,'30089','C00033','2011-08-25 16:28:56','2011-08-25 16:28:56'),(4,1278,'15366','C00033','2011-08-25 16:28:56','2011-08-25 16:28:56'),(5,2284,'42111','C01432','2011-08-25 16:29:11','2011-08-25 16:29:11'),(6,2284,'24996','C01432','2011-08-25 16:29:11','2011-08-25 16:29:11'),(7,2284,'28358','C01432','2011-08-25 16:29:11','2011-08-25 16:29:11'),(8,1924,'30031','C00042','2011-08-25 16:29:17','2011-08-25 16:29:17'),(9,1924,'15741','C00042','2011-08-25 16:29:17','2011-08-25 16:29:17'),(10,29,NULL,NULL,'2011-08-25 16:29:21','2011-08-25 16:29:21'),(11,1314,'16174','C00206','2011-08-25 16:29:21','2011-08-25 16:29:21'),(12,1307,'16284','C00131','2011-08-25 16:29:21','2011-08-25 16:29:21'),(13,1922,'16810','C00026','2011-08-25 16:29:21','2011-08-25 16:29:21'),(14,1922,'30915','C00026','2011-08-25 16:29:21','2011-08-25 16:29:21'),(15,31,'17835','C00631','2011-08-25 16:29:21','2011-08-25 16:29:21'),(16,31,'24344','C00631','2011-08-25 16:29:21','2011-08-25 16:29:21'),(17,32,'44897','C00074','2011-08-25 16:29:21','2011-08-25 16:29:21'),(18,32,'18021','C00074','2011-08-25 16:29:21','2011-08-25 16:29:21'),(19,30,'17050','C00597','2011-08-25 16:29:21','2011-08-25 16:29:21'),(20,30,'17050','C00197','2011-08-25 16:29:21','2011-08-25 16:29:21'),(21,21216,'17794','C00197','2011-08-25 16:29:21','2011-08-25 16:29:21'),(22,2024,'16863','C00345','2011-08-25 16:29:21','2011-08-25 16:29:21'),(23,2024,'48928','C00345','2011-08-25 16:29:21','2011-08-25 16:29:21'),(24,1366,'16938','C01236','2011-08-25 16:29:22','2011-08-25 16:29:22'),(25,22801,NULL,NULL,'2011-08-25 16:29:22','2011-08-25 16:29:22'),(26,1292,'15343','C00084','2011-08-25 16:29:22','2011-08-25 16:29:22'),(27,2054,'15688','C00466','2011-08-25 16:29:22','2011-08-25 16:29:22'),(28,1316,'15350','C00227','2011-08-25 16:29:22','2011-08-25 16:29:22'),(29,1316,'13711','C00227','2011-08-25 16:29:22','2011-08-25 16:29:22'),(30,1316,'22191','C00227','2011-08-25 16:29:22','2011-08-25 16:29:22'),(31,1276,'15351','C00024','2011-08-25 16:29:22','2011-08-25 16:29:22'),(32,35,'16761','C00008','2011-08-25 16:29:22','2011-08-25 16:29:22'),(33,34,'30616','C00002','2011-08-25 16:29:22','2011-08-25 16:29:22'),(34,34,'15422','C00002','2011-08-25 16:29:22','2011-08-25 16:29:22'),(35,1364,'17925','C00267','2011-08-25 16:29:22','2011-08-25 16:29:22'),(36,24,'17665','C00668','2011-08-25 16:29:22','2011-08-25 16:29:22'),(37,1273,'16027','C00020','2011-08-25 16:29:22','2011-08-25 16:29:22'),(38,26,'28013','C05378','2011-08-25 16:29:22','2011-08-25 16:29:22'),(39,25,'16084','C05345','2011-08-25 16:29:22','2011-08-25 16:29:22'),(40,1378,'15903','C00221','2011-08-25 16:29:22','2011-08-25 16:29:22'),(41,1302,'3611','C00112','2011-08-25 16:29:22','2011-08-25 16:29:22'),(42,1302,'17239','C00112','2011-08-25 16:29:22','2011-08-25 16:29:22'),(43,1952,'16947','C00158','2011-08-25 16:29:22','2011-08-25 16:29:22'),(44,1952,'30769','C00158','2011-08-25 16:29:22','2011-08-25 16:29:22'),(45,1286,'37563','C00063','2011-08-25 16:29:23','2011-08-25 16:29:23'),(46,1286,'17677','C00063','2011-08-25 16:29:23','2011-08-25 16:29:23'),(47,1324,'48153','C00279','2011-08-25 16:29:23','2011-08-25 16:29:23'),(48,1324,'16897','C00279','2011-08-25 16:29:23','2011-08-25 16:29:23'),(49,1407,'4167','C00031','2011-08-25 16:29:23','2011-08-25 16:29:23'),(50,1407,'17634','C00031','2011-08-25 16:29:23','2011-08-25 16:29:23'),(51,1465,'37736','C00354','2011-08-25 16:29:23','2011-08-25 16:29:23'),(52,1465,'16905','C00354','2011-08-25 16:29:23','2011-08-25 16:29:23'),(53,1351,'37515','C01094','2011-08-25 16:29:23','2011-08-25 16:29:23'),(54,1351,'18105','C01094','2011-08-25 16:29:23','2011-08-25 16:29:23'),(55,1374,'15946','C00085','2011-08-25 16:29:23','2011-08-25 16:29:23'),(56,2484,'15945','C15483','2011-08-25 16:29:23','2011-08-25 16:29:23'),(57,2484,'15945','C02669','2011-08-25 16:29:23','2011-08-25 16:29:23'),(58,1661,'12936','C00124','2011-08-25 16:29:23','2011-08-25 16:29:23'),(59,1661,'4139','C00124','2011-08-25 16:29:23','2011-08-25 16:29:23'),(60,1971,'16217','C00198','2011-08-25 16:29:23','2011-08-25 16:29:23'),(61,1405,'14314','C00092','2011-08-25 16:29:23','2011-08-25 16:29:23'),(62,1405,'15954','C00092','2011-08-25 16:29:23','2011-08-25 16:29:23'),(63,1405,'4170','C00092','2011-08-25 16:29:23','2011-08-25 16:29:23'),(64,1409,'17378','C00577','2011-08-25 16:29:23','2011-08-25 16:29:23'),(65,27,'29052','C00118','2011-08-25 16:29:23','2011-08-25 16:29:23'),(66,28,'16108','C00111','2011-08-25 16:29:23','2011-08-25 16:29:23'),(67,38,'16908','C00004','2011-08-25 16:29:24','2011-08-25 16:29:24'),(68,6102,'15867','C02266','2011-08-25 16:29:24','2011-08-25 16:29:24'),(69,1659,'15936','C00181','2011-08-25 16:29:24','2011-08-25 16:29:24'),(70,21267,NULL,NULL,'2011-08-25 16:29:24','2011-08-25 16:29:24'),(71,56,'16236','C00469','2011-08-25 16:29:24','2011-08-25 16:29:24'),(72,1285,'15740','C00058','2011-08-25 16:29:24','2011-08-25 16:29:24'),(73,1285,'30751','C00058','2011-08-25 16:29:24','2011-08-25 16:29:24'),(74,1910,'18012','C00122','2011-08-25 16:29:24','2011-08-25 16:29:24'),(75,1910,'29806','C00122','2011-08-25 16:29:24','2011-08-25 16:29:24'),(76,1280,'17552','C00035','2011-08-25 16:29:24','2011-08-25 16:29:24'),(77,1404,'4170','C00092','2011-08-25 16:29:24','2011-08-25 16:29:24'),(78,1303,'17754','C00116','2011-08-25 16:29:24','2011-08-25 16:29:24'),(79,1282,'37565','C00044','2011-08-25 16:29:24','2011-08-25 16:29:24'),(80,1282,'15996','C00044','2011-08-25 16:29:24','2011-08-25 16:29:24'),(81,40,'15377','C00001','2011-08-25 16:29:24','2011-08-25 16:29:24'),(82,1299,'17808','C00104','2011-08-25 16:29:24','2011-08-25 16:29:24'),(83,1291,'16039','C00081','2011-08-25 16:29:24','2011-08-25 16:29:24'),(84,2013,'16087','C00311','2011-08-25 16:29:25','2011-08-25 16:29:25'),(85,2013,'30887','C00311','2011-08-25 16:29:25','2011-08-25 16:29:25'),(86,2013,'151','C00311','2011-08-25 16:29:25','2011-08-25 16:29:25'),(87,1918,'30797','C00149','2011-08-25 16:29:25','2011-08-25 16:29:25'),(88,1918,'15589','C00149','2011-08-25 16:29:25','2011-08-25 16:29:25'),(89,2138,'6650','C00711','2011-08-25 16:29:25','2011-08-25 16:29:25'),(90,2138,'15595','C00711','2011-08-25 16:29:25','2011-08-25 16:29:25'),(91,2138,'6650','C00149','2011-08-25 16:29:25','2011-08-25 16:29:25'),(92,2138,'15595','C00149','2011-08-25 16:29:25','2011-08-25 16:29:25'),(93,1262,'16474','C00005','2011-08-25 16:29:25','2011-08-25 16:29:25'),(94,36,'18367','C00009','2011-08-25 16:29:25','2011-08-25 16:29:25'),(95,36,'35780','C00009','2011-08-25 16:29:25','2011-08-25 16:29:25'),(96,36,'26078','C00009','2011-08-25 16:29:25','2011-08-25 16:29:25'),(97,1915,'16452','C00036','2011-08-25 16:29:25','2011-08-25 16:29:25'),(98,1915,'30744','C00036','2011-08-25 16:29:25','2011-08-25 16:29:25'),(99,1931,'15380','C00091','2011-08-25 16:29:25','2011-08-25 16:29:25'),(100,91,'16551','C01083','2011-08-25 16:29:25','2011-08-25 16:29:25'),(101,91,'27082','C01083','2011-08-25 16:29:25','2011-08-25 16:29:25'),(102,1269,'17659','C00015','2011-08-25 16:29:26','2011-08-25 16:29:26'),(103,1288,'46398','C00075','2011-08-25 16:29:26','2011-08-25 16:29:26'),(104,1288,'15713','C00075','2011-08-25 16:29:26','2011-08-25 16:29:26'),(105,1263,'18009','C11037','2011-09-09 09:27:51','2011-09-09 09:27:51'),(106,1263,'44409','C11037','2011-09-09 09:27:51','2011-09-09 09:27:51'),(107,1263,'25523','C11037','2011-09-09 09:27:51','2011-09-09 09:27:51'),(108,1263,'18009','C00006','2011-09-09 09:27:51','2011-09-09 09:27:51'),(109,1263,'44409','C00006','2011-09-09 09:27:51','2011-09-09 09:27:51'),(110,1263,'25523','C00006','2011-09-09 09:27:51','2011-09-09 09:27:51'),(111,1406,'17234','C00293','2011-09-09 09:30:39','2011-09-09 09:30:39'),(112,1406,'17234','C00031','2011-09-09 09:30:39','2011-09-09 09:30:39'),(113,21215,'16001','C00236','2011-09-12 14:07:33','2011-09-12 14:07:33'),(114,39,'15378','C00080','2011-09-12 14:24:00','2011-09-12 14:24:00'),(115,29,NULL,NULL,'2011-11-01 13:44:43','2011-11-01 13:44:43'),(116,29,NULL,NULL,'2011-11-01 13:44:43','2011-11-01 13:44:43'),(117,22801,NULL,NULL,'2011-11-01 13:44:47','2011-11-01 13:44:47'),(118,2280,'16449','C01401','2011-11-01 13:44:51','2011-11-01 13:44:51'),(119,2280,'46217','C01401','2011-11-01 13:44:51','2011-11-01 13:44:51'),(120,2280,'16977','C01401','2011-11-01 13:44:51','2011-11-01 13:44:51'),(121,2410,'29016','C02385','2011-11-01 13:44:52','2011-11-01 13:44:52'),(122,1266,'16526','C00011','2011-11-01 13:44:55','2011-11-01 13:44:55'),(123,2142,'17561','C00736','2011-11-01 13:44:55','2011-11-01 13:44:55'),(124,2142,'15356','C00736','2011-11-01 13:44:55','2011-11-01 13:44:55'),(125,37,'44215','C00004','2011-11-01 13:45:00','2011-11-01 13:45:00'),(126,37,'13389','C00004','2011-11-01 13:45:00','2011-11-01 13:45:00'),(127,37,'15846','C00004','2011-11-01 13:45:00','2011-11-01 13:45:00'),(128,37,'44215','C00003','2011-11-01 13:45:00','2011-11-01 13:45:00'),(129,37,'13389','C00003','2011-11-01 13:45:00','2011-11-01 13:45:00'),(130,37,'15846','C00003','2011-11-01 13:45:00','2011-11-01 13:45:00'),(131,21267,NULL,NULL,'2011-11-01 13:45:02','2011-11-01 13:45:02'),(132,2010,'29987','C00302','2011-11-01 13:45:04','2011-11-01 13:45:04'),(133,2010,'18237','C00302','2011-11-01 13:45:04','2011-11-01 13:45:04'),(134,2010,'14321','C00302','2011-11-01 13:45:04','2011-11-01 13:45:04'),(135,2010,'29987','C00025','2011-11-01 13:45:04','2011-11-01 13:45:04'),(136,2010,'18237','C00025','2011-11-01 13:45:04','2011-11-01 13:45:04'),(137,2010,'14321','C00025','2011-11-01 13:45:04','2011-11-01 13:45:04'),(138,29,NULL,NULL,'2011-11-01 13:45:05','2011-11-01 13:45:05'),(139,66,'29947','C00037','2011-11-01 13:45:06','2011-11-01 13:45:06'),(140,66,'15428','C00037','2011-11-01 13:45:06','2011-11-01 13:45:06'),(141,2151,'27570','C00768','2011-11-01 13:45:08','2011-11-01 13:45:08'),(142,2151,'15971','C00768','2011-11-01 13:45:08','2011-11-01 13:45:08'),(143,21059,'15603','C16439','2011-11-01 13:45:11','2011-11-01 13:45:11'),(144,21059,'25017','C16439','2011-11-01 13:45:11','2011-11-01 13:45:11'),(145,22945,'25094','C16440','2011-11-01 13:45:11','2011-11-01 13:45:11'),(146,2315,'16811','C01733','2011-11-01 13:45:11','2011-11-01 13:45:11'),(147,2315,'16643','C01733','2011-11-01 13:45:11','2011-11-01 13:45:11'),(148,2315,'16811','C00073','2011-11-01 13:45:11','2011-11-01 13:45:11'),(149,2315,'16643','C00073','2011-11-01 13:45:11','2011-11-01 13:45:11'),(150,1268,'16134','C00014','2011-11-01 13:45:16','2011-11-01 13:45:16'),(151,1264,'25805','C00007','2011-11-01 13:45:17','2011-11-01 13:45:17'),(152,1264,'15379','C00007','2011-11-01 13:45:17','2011-11-01 13:45:17'),(153,1264,'25805','C00704','2011-11-01 13:45:17','2011-11-01 13:45:17'),(154,1264,'15379','C00704','2011-11-01 13:45:17','2011-11-01 13:45:17'),(155,2365,'17295','C02057','2011-11-01 13:45:18','2011-11-01 13:45:18'),(156,2365,'28044','C02057','2011-11-01 13:45:18','2011-11-01 13:45:18'),(157,25536,'17203','C16435','2011-11-01 13:45:20','2011-11-01 13:45:20'),(158,2140,'17822','C00716','2011-11-01 13:45:21','2011-11-01 13:45:21'),(159,2140,'17115','C00716','2011-11-01 13:45:21','2011-11-01 13:45:21'),(160,2140,'17822','C00065','2011-11-01 13:45:21','2011-11-01 13:45:21'),(161,2140,'17115','C00065','2011-11-01 13:45:21','2011-11-01 13:45:21'),(162,27463,NULL,NULL,'2011-11-01 13:45:22','2011-11-01 13:45:22'),(163,2291,'17895','C00082','2011-11-01 13:45:24','2011-11-01 13:45:24'),(164,2291,'18186','C00082','2011-11-01 13:45:24','2011-11-01 13:45:24'),(165,2291,'17895','C01536','2011-11-01 13:45:24','2011-11-01 13:45:24'),(166,2291,'18186','C01536','2011-11-01 13:45:24','2011-11-01 13:45:24'),(167,23113,'27266','C16436','2011-11-01 13:45:25','2011-11-01 13:45:25'),(168,23113,'16414','C16436','2011-11-01 13:45:25','2011-11-01 13:45:25'),(169,29,NULL,NULL,'2012-12-20 12:52:44','2012-12-20 12:52:44'),(170,29,NULL,NULL,'2012-12-20 12:52:44','2012-12-20 12:52:44'),(171,1812,'15925','C04442','2012-12-20 12:52:44','2012-12-20 12:52:44'),(172,22801,NULL,NULL,'2012-12-20 12:52:47','2012-12-20 12:52:47'),(173,1473,'18189','C03736','2012-12-20 12:52:49','2012-12-20 12:52:49'),(174,21267,NULL,NULL,'2012-12-20 12:52:56','2012-12-20 12:52:56'),(175,29,NULL,NULL,'2012-12-20 12:52:57','2012-12-20 12:52:57'),(176,1306,'17202','C00130','2012-12-20 12:52:59','2012-12-20 12:52:59'),(177,2300,'18257','C01602','2012-12-20 12:53:03','2012-12-20 12:53:03'),(178,2300,'44667','C01602','2012-12-20 12:53:03','2012-12-20 12:53:03'),(179,2300,'32964','C01602','2012-12-20 12:53:03','2012-12-20 12:53:03'),(180,27463,NULL,NULL,'2012-12-20 12:53:08','2012-12-20 12:53:08');
/*!40000 ALTER TABLE `mappings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `measured_items`
--

DROP TABLE IF EXISTS `measured_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `measured_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `factors_studied` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1045310063 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `measured_items`
--

LOCK TABLES `measured_items` WRITE;
/*!40000 ALTER TABLE `measured_items` DISABLE KEYS */;
INSERT INTO `measured_items` VALUES (56985099,'acidity/PH','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(102398331,'glucose pulse','2019-09-03 12:32:48','2019-09-03 12:32:48',0),(354314687,'dry biomass concentration','2019-09-03 12:32:48','2019-09-03 12:32:48',0),(454233679,'gas flow rate','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(482839832,'concentration','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(531603560,'pressure','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(720333100,'optical density 600 nm','2019-09-03 12:32:48','2019-09-03 12:32:48',0),(736627738,'stiring rate','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(753491646,'dilution rate','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(798267462,'time','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(828043506,'buffer','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(896634288,'growth medium','2019-09-03 12:32:48','2019-09-03 12:32:48',1),(1012502157,'specific concentration','2019-09-03 12:32:48','2019-09-03 12:32:48',0),(1045310062,'temperature','2019-09-03 12:32:48','2019-09-03 12:32:48',1);
/*!40000 ALTER TABLE `measured_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `message_logs`
--

DROP TABLE IF EXISTS `message_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `message_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `message_type` int(11) DEFAULT NULL,
  `details` text,
  `resource_id` int(11) DEFAULT NULL,
  `resource_type` varchar(255) DEFAULT NULL,
  `sender_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_message_logs_on_resource_type_and_resource_id` (`resource_type`,`resource_id`),
  KEY `index_message_logs_on_sender_id` (`sender_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `message_logs`
--

LOCK TABLES `message_logs` WRITE;
/*!40000 ALTER TABLE `message_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `message_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `model_auth_lookup`
--

DROP TABLE IF EXISTS `model_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_model_auth_lookup_on_user_id_and_asset_id_and_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_model_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `model_auth_lookup`
--

LOCK TABLES `model_auth_lookup` WRITE;
/*!40000 ALTER TABLE `model_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `model_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `model_formats`
--

DROP TABLE IF EXISTS `model_formats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_formats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `model_formats`
--

LOCK TABLES `model_formats` WRITE;
/*!40000 ALTER TABLE `model_formats` DISABLE KEYS */;
INSERT INTO `model_formats` VALUES (1,'BioPAX','2019-09-03 12:32:52','2019-09-03 12:32:52'),(2,'CellML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(3,'FieldML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(4,'GraphML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(5,'Image','2019-09-03 12:32:52','2019-09-03 12:32:52'),(6,'KGML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(7,'Mathematica','2019-09-03 12:32:52','2019-09-03 12:32:52'),(8,'Matlab package','2019-09-03 12:32:52','2019-09-03 12:32:52'),(9,'MFAML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(10,'PDF (Model description)','2019-09-03 12:32:52','2019-09-03 12:32:52'),(11,'R package','2019-09-03 12:32:52','2019-09-03 12:32:52'),(12,'SBML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(13,'SciLab','2019-09-03 12:32:52','2019-09-03 12:32:52'),(14,'Simile XML v3','2019-09-03 12:32:52','2019-09-03 12:32:52'),(15,'SVG','2019-09-03 12:32:52','2019-09-03 12:32:52'),(16,'SXML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(17,'Virtual Cell Markup Language (VCML)','2019-09-03 12:32:52','2019-09-03 12:32:52'),(18,'XPP','2019-09-03 12:32:52','2019-09-03 12:32:52'),(19,'Copasi','2019-09-03 12:32:52','2019-09-03 12:32:52'),(20,'MathML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(21,'XGMML','2019-09-03 12:32:52','2019-09-03 12:32:52'),(22,'SBGN-ML PD','2019-09-03 12:32:52','2019-09-03 12:32:52');
/*!40000 ALTER TABLE `model_formats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `model_images`
--

DROP TABLE IF EXISTS `model_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model_id` int(11) DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `content_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `image_width` int(11) DEFAULT NULL,
  `image_height` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `model_images`
--

LOCK TABLES `model_images` WRITE;
/*!40000 ALTER TABLE `model_images` DISABLE KEYS */;
/*!40000 ALTER TABLE `model_images` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `model_types`
--

DROP TABLE IF EXISTS `model_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `model_types`
--

LOCK TABLES `model_types` WRITE;
/*!40000 ALTER TABLE `model_types` DISABLE KEYS */;
INSERT INTO `model_types` VALUES (1,'Ordinary differential equations (ODE)','2019-09-03 12:32:52','2019-09-03 12:32:52'),(2,'Partial differential equations (PDE)','2019-09-03 12:32:52','2019-09-03 12:32:52'),(3,'Boolean network','2019-09-03 12:32:52','2019-09-03 12:32:52'),(4,'Petri net','2019-09-03 12:32:52','2019-09-03 12:32:52'),(5,'Linear equations','2019-09-03 12:32:52','2019-09-03 12:32:52'),(6,'Algebraic equations','2019-09-03 12:32:52','2019-09-03 12:32:52'),(7,'Bayesian network','2019-09-03 12:32:52','2019-09-03 12:32:52'),(8,'Graphical model','2019-09-03 12:32:52','2019-09-03 12:32:52'),(9,'Stoichiometric model','2019-09-03 12:32:52','2019-09-03 12:32:52'),(10,'Agent based modelling','2019-09-03 12:32:52','2019-09-03 12:32:52'),(11,'Metabolic network','2019-09-03 12:32:52','2019-09-03 12:32:52');
/*!40000 ALTER TABLE `model_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `model_versions`
--

DROP TABLE IF EXISTS `model_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `revision_comments` text,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `recommended_environment_id` int(11) DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `organism_id` int(11) DEFAULT NULL,
  `model_type_id` int(11) DEFAULT NULL,
  `model_format_id` int(11) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `imported_source` varchar(255) DEFAULT NULL,
  `imported_url` varchar(255) DEFAULT NULL,
  `model_image_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_model_versions_on_contributor` (`contributor_id`),
  KEY `index_model_versions_on_model_id` (`model_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `model_versions`
--

LOCK TABLES `model_versions` WRITE;
/*!40000 ALTER TABLE `model_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `model_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `model_versions_projects`
--

DROP TABLE IF EXISTS `model_versions_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_versions_projects` (
  `project_id` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `model_versions_projects`
--

LOCK TABLES `model_versions_projects` WRITE;
/*!40000 ALTER TABLE `model_versions_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `model_versions_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `models`
--

DROP TABLE IF EXISTS `models`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `models` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `recommended_environment_id` int(11) DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `organism_id` int(11) DEFAULT NULL,
  `model_type_id` int(11) DEFAULT NULL,
  `model_format_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT '1',
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `imported_source` varchar(255) DEFAULT NULL,
  `imported_url` varchar(255) DEFAULT NULL,
  `model_image_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_models_on_contributor` (`contributor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `models`
--

LOCK TABLES `models` WRITE;
/*!40000 ALTER TABLE `models` DISABLE KEYS */;
/*!40000 ALTER TABLE `models` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `models_projects`
--

DROP TABLE IF EXISTS `models_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `models_projects` (
  `project_id` int(11) DEFAULT NULL,
  `model_id` int(11) DEFAULT NULL,
  KEY `index_models_projects_on_model_id_and_project_id` (`model_id`,`project_id`),
  KEY `index_models_projects_on_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `models_projects`
--

LOCK TABLES `models_projects` WRITE;
/*!40000 ALTER TABLE `models_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `models_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `moderatorships`
--

DROP TABLE IF EXISTS `moderatorships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `moderatorships` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `forum_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_moderatorships_on_forum_id` (`forum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `moderatorships`
--

LOCK TABLES `moderatorships` WRITE;
/*!40000 ALTER TABLE `moderatorships` DISABLE KEYS */;
/*!40000 ALTER TABLE `moderatorships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `modifications`
--

DROP TABLE IF EXISTS `modifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `modifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `symbol` varchar(255) DEFAULT NULL,
  `description` text,
  `position` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `modifications`
--

LOCK TABLES `modifications` WRITE;
/*!40000 ALTER TABLE `modifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `modifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_auth_lookup`
--

DROP TABLE IF EXISTS `node_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_n_auth_lookup_on_user_id_and_asset_id_and_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_n_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_auth_lookup`
--

LOCK TABLES `node_auth_lookup` WRITE;
/*!40000 ALTER TABLE `node_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_versions`
--

DROP TABLE IF EXISTS `node_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `node_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `revision_comments` text,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_node_versions_on_contributor` (`contributor_id`),
  KEY `index_node_versions_on_node_id` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_versions`
--

LOCK TABLES `node_versions` WRITE;
/*!40000 ALTER TABLE `node_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node_versions_projects`
--

DROP TABLE IF EXISTS `node_versions_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `node_versions_projects` (
  `project_id` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node_versions_projects`
--

LOCK TABLES `node_versions_projects` WRITE;
/*!40000 ALTER TABLE `node_versions_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `node_versions_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nodes`
--

DROP TABLE IF EXISTS `nodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nodes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `version` int(11) DEFAULT '1',
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_nodes_on_contributor` (`contributor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nodes`
--

LOCK TABLES `nodes` WRITE;
/*!40000 ALTER TABLE `nodes` DISABLE KEYS */;
/*!40000 ALTER TABLE `nodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nodes_projects`
--

DROP TABLE IF EXISTS `nodes_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nodes_projects` (
  `project_id` int(11) DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nodes_projects`
--

LOCK TABLES `nodes_projects` WRITE;
/*!40000 ALTER TABLE `nodes_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `nodes_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifiee_infos`
--

DROP TABLE IF EXISTS `notifiee_infos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifiee_infos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `notifiee_id` int(11) DEFAULT NULL,
  `notifiee_type` varchar(255) DEFAULT NULL,
  `unique_key` varchar(255) DEFAULT NULL,
  `receive_notifications` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifiee_infos`
--

LOCK TABLES `notifiee_infos` WRITE;
/*!40000 ALTER TABLE `notifiee_infos` DISABLE KEYS */;
INSERT INTO `notifiee_infos` VALUES (1,1,'Person','f74186e0-b074-0137-134b-721898481898',1,'2019-09-03 12:33:33','2019-09-03 12:33:33'),(2,2,'Person','89fefee0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:39','2019-09-03 12:37:39'),(3,3,'Person','8a6c29e0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:39','2019-09-03 12:37:39'),(4,4,'Person','8ae0af00-b075-0137-1348-721898481898',1,'2019-09-03 12:37:40','2019-09-03 12:37:40'),(5,5,'Person','8b63c1c0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:41','2019-09-03 12:37:41'),(6,6,'Person','8bf6c140-b075-0137-1348-721898481898',1,'2019-09-03 12:37:42','2019-09-03 12:37:42'),(7,7,'Person','8c90aef0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:43','2019-09-03 12:37:43'),(8,8,'Person','8d33fd10-b075-0137-1348-721898481898',1,'2019-09-03 12:37:44','2019-09-03 12:37:44'),(9,9,'Person','8d9d2dd0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:45','2019-09-03 12:37:45'),(10,10,'Person','8e064850-b075-0137-1348-721898481898',1,'2019-09-03 12:37:45','2019-09-03 12:37:45'),(11,11,'Person','8e7acc60-b075-0137-1348-721898481898',1,'2019-09-03 12:37:46','2019-09-03 12:37:46'),(12,12,'Person','8ef8b3b0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:47','2019-09-03 12:37:47'),(13,13,'Person','8f8291f0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:48','2019-09-03 12:37:48'),(14,14,'Person','90214860-b075-0137-1348-721898481898',1,'2019-09-03 12:37:49','2019-09-03 12:37:49'),(15,15,'Person','90bfe4b0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:50','2019-09-03 12:37:50'),(16,16,'Person','916bd490-b075-0137-1348-721898481898',1,'2019-09-03 12:37:51','2019-09-03 12:37:51'),(17,17,'Person','921fcad0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:52','2019-09-03 12:37:52'),(18,18,'Person','928b66c0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:53','2019-09-03 12:37:53'),(19,19,'Person','93014990-b075-0137-1348-721898481898',1,'2019-09-03 12:37:54','2019-09-03 12:37:54'),(20,20,'Person','9380ff40-b075-0137-1348-721898481898',1,'2019-09-03 12:37:55','2019-09-03 12:37:55'),(21,21,'Person','94163cf0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:56','2019-09-03 12:37:56'),(22,22,'Person','94b93d00-b075-0137-1348-721898481898',1,'2019-09-03 12:37:57','2019-09-03 12:37:57'),(23,23,'Person','95584740-b075-0137-1348-721898481898',1,'2019-09-03 12:37:58','2019-09-03 12:37:58'),(24,24,'Person','95c55720-b075-0137-1348-721898481898',1,'2019-09-03 12:37:58','2019-09-03 12:37:58'),(25,25,'Person','963ab2e0-b075-0137-1348-721898481898',1,'2019-09-03 12:37:59','2019-09-03 12:37:59'),(26,26,'Person','96bab6d0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:00','2019-09-03 12:38:00'),(27,27,'Person','974b3630-b075-0137-1348-721898481898',1,'2019-09-03 12:38:01','2019-09-03 12:38:01'),(28,28,'Person','97e07ff0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:02','2019-09-03 12:38:02'),(29,29,'Person','98807c30-b075-0137-1348-721898481898',1,'2019-09-03 12:38:03','2019-09-03 12:38:03'),(30,30,'Person','9932c7f0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:04','2019-09-03 12:38:04'),(31,31,'Person','9a039f00-b075-0137-1348-721898481898',1,'2019-09-03 12:38:06','2019-09-03 12:38:06'),(32,32,'Person','9a753010-b075-0137-1348-721898481898',1,'2019-09-03 12:38:06','2019-09-03 12:38:06'),(33,33,'Person','9aef2700-b075-0137-1348-721898481898',1,'2019-09-03 12:38:07','2019-09-03 12:38:07'),(34,34,'Person','9b6c9d30-b075-0137-1348-721898481898',1,'2019-09-03 12:38:08','2019-09-03 12:38:08'),(35,35,'Person','9bfd2c30-b075-0137-1348-721898481898',1,'2019-09-03 12:38:09','2019-09-03 12:38:09'),(36,36,'Person','9c93bdb0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:10','2019-09-03 12:38:10'),(37,37,'Person','9d323660-b075-0137-1348-721898481898',1,'2019-09-03 12:38:11','2019-09-03 12:38:11'),(38,38,'Person','9dd05b40-b075-0137-1348-721898481898',1,'2019-09-03 12:38:12','2019-09-03 12:38:12'),(39,39,'Person','9e3b4dc0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:13','2019-09-03 12:38:13'),(40,40,'Person','9eb491e0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:13','2019-09-03 12:38:13'),(41,41,'Person','9f38eba0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:14','2019-09-03 12:38:14'),(42,42,'Person','9fbac170-b075-0137-1348-721898481898',1,'2019-09-03 12:38:15','2019-09-03 12:38:15'),(43,43,'Person','a04e1680-b075-0137-1348-721898481898',1,'2019-09-03 12:38:16','2019-09-03 12:38:16'),(44,44,'Person','a0fa9470-b075-0137-1348-721898481898',1,'2019-09-03 12:38:17','2019-09-03 12:38:17'),(45,45,'Person','a1a5f7c0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:18','2019-09-03 12:38:18'),(46,46,'Person','a255a530-b075-0137-1348-721898481898',1,'2019-09-03 12:38:20','2019-09-03 12:38:20'),(47,47,'Person','a31a1db0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:21','2019-09-03 12:38:21'),(48,48,'Person','a3e3ff90-b075-0137-1348-721898481898',1,'2019-09-03 12:38:22','2019-09-03 12:38:22'),(49,49,'Person','a4af65e0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:23','2019-09-03 12:38:23'),(50,50,'Person','a58e4080-b075-0137-1348-721898481898',1,'2019-09-03 12:38:25','2019-09-03 12:38:25'),(51,51,'Person','a67fd0b0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:27','2019-09-03 12:38:27'),(52,52,'Person','a7a90060-b075-0137-1348-721898481898',1,'2019-09-03 12:38:28','2019-09-03 12:38:28'),(53,53,'Person','a8b6ede0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:30','2019-09-03 12:38:30'),(54,54,'Person','a9c839e0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:32','2019-09-03 12:38:32'),(55,55,'Person','aae5b670-b075-0137-1348-721898481898',1,'2019-09-03 12:38:34','2019-09-03 12:38:34'),(56,56,'Person','ac009550-b075-0137-1348-721898481898',1,'2019-09-03 12:38:36','2019-09-03 12:38:36'),(57,57,'Person','ac754120-b075-0137-1348-721898481898',1,'2019-09-03 12:38:37','2019-09-03 12:38:37'),(58,58,'Person','acf21fd0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:37','2019-09-03 12:38:37'),(59,59,'Person','ad7b4750-b075-0137-1348-721898481898',1,'2019-09-03 12:38:38','2019-09-03 12:38:38'),(60,60,'Person','ae113230-b075-0137-1348-721898481898',1,'2019-09-03 12:38:39','2019-09-03 12:38:39'),(61,61,'Person','aeaddcc0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:40','2019-09-03 12:38:40'),(62,62,'Person','af5c5420-b075-0137-1348-721898481898',1,'2019-09-03 12:38:41','2019-09-03 12:38:41'),(63,63,'Person','b00f3270-b075-0137-1348-721898481898',1,'2019-09-03 12:38:43','2019-09-03 12:38:43'),(64,64,'Person','b0d39ba0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:44','2019-09-03 12:38:44'),(65,65,'Person','b19db3e0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:45','2019-09-03 12:38:45'),(66,66,'Person','b26f5010-b075-0137-1348-721898481898',1,'2019-09-03 12:38:47','2019-09-03 12:38:47'),(67,67,'Person','b2db7e90-b075-0137-1348-721898481898',1,'2019-09-03 12:38:47','2019-09-03 12:38:47'),(68,68,'Person','b3523620-b075-0137-1348-721898481898',1,'2019-09-03 12:38:48','2019-09-03 12:38:48'),(69,69,'Person','b3d2c850-b075-0137-1348-721898481898',1,'2019-09-03 12:38:49','2019-09-03 12:38:49'),(70,70,'Person','b4670820-b075-0137-1348-721898481898',1,'2019-09-03 12:38:50','2019-09-03 12:38:50'),(71,71,'Person','b503fa10-b075-0137-1348-721898481898',1,'2019-09-03 12:38:51','2019-09-03 12:38:51'),(72,72,'Person','b5aa0c20-b075-0137-1348-721898481898',1,'2019-09-03 12:38:52','2019-09-03 12:38:52'),(73,73,'Person','b66605d0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:53','2019-09-03 12:38:53'),(74,74,'Person','b71cf990-b075-0137-1348-721898481898',1,'2019-09-03 12:38:54','2019-09-03 12:38:54'),(75,75,'Person','b7e2b3e0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:56','2019-09-03 12:38:56'),(76,76,'Person','b8afa300-b075-0137-1348-721898481898',1,'2019-09-03 12:38:57','2019-09-03 12:38:57'),(77,77,'Person','b983c690-b075-0137-1348-721898481898',1,'2019-09-03 12:38:58','2019-09-03 12:38:58'),(78,78,'Person','b9f84fc0-b075-0137-1348-721898481898',1,'2019-09-03 12:38:59','2019-09-03 12:38:59'),(79,79,'Person','ba724340-b075-0137-1348-721898481898',1,'2019-09-03 12:39:00','2019-09-03 12:39:00'),(80,80,'Person','bafed100-b075-0137-1348-721898481898',1,'2019-09-03 12:39:01','2019-09-03 12:39:01'),(81,81,'Person','bb955c20-b075-0137-1348-721898481898',1,'2019-09-03 12:39:02','2019-09-03 12:39:02'),(82,82,'Person','bc367250-b075-0137-1348-721898481898',1,'2019-09-03 12:39:03','2019-09-03 12:39:03'),(83,83,'Person','bcdb7ef0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:04','2019-09-03 12:39:04'),(84,84,'Person','bd917eb0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:05','2019-09-03 12:39:05'),(85,85,'Person','be59ab50-b075-0137-1348-721898481898',1,'2019-09-03 12:39:07','2019-09-03 12:39:07'),(86,86,'Person','bf1d9100-b075-0137-1348-721898481898',1,'2019-09-03 12:39:08','2019-09-03 12:39:08'),(87,87,'Person','bfe30400-b075-0137-1348-721898481898',1,'2019-09-03 12:39:09','2019-09-03 12:39:09'),(88,88,'Person','c0c13830-b075-0137-1348-721898481898',1,'2019-09-03 12:39:11','2019-09-03 12:39:11'),(89,89,'Person','c13450a0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:11','2019-09-03 12:39:11'),(90,90,'Person','c1b6c5d0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:12','2019-09-03 12:39:12'),(91,91,'Person','c2425e40-b075-0137-1348-721898481898',1,'2019-09-03 12:39:13','2019-09-03 12:39:13'),(92,92,'Person','c2d316d0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:14','2019-09-03 12:39:14'),(93,93,'Person','c370dc00-b075-0137-1348-721898481898',1,'2019-09-03 12:39:15','2019-09-03 12:39:15'),(94,94,'Person','c4195900-b075-0137-1348-721898481898',1,'2019-09-03 12:39:16','2019-09-03 12:39:16'),(95,95,'Person','c4c3f970-b075-0137-1348-721898481898',1,'2019-09-03 12:39:17','2019-09-03 12:39:17'),(96,96,'Person','c57210c0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:18','2019-09-03 12:39:18'),(97,97,'Person','c635e660-b075-0137-1348-721898481898',1,'2019-09-03 12:39:20','2019-09-03 12:39:20'),(98,98,'Person','c6fc1ef0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:21','2019-09-03 12:39:21'),(99,99,'Person','c7e3fc90-b075-0137-1348-721898481898',1,'2019-09-03 12:39:23','2019-09-03 12:39:23'),(100,100,'Person','c8cfadf0-b075-0137-1348-721898481898',1,'2019-09-03 12:39:24','2019-09-03 12:39:24');
/*!40000 ALTER TABLE `notifiee_infos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `number_value_versions`
--

DROP TABLE IF EXISTS `number_value_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `number_value_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `number_value_id` int(11) NOT NULL,
  `version` int(11) NOT NULL,
  `version_creator_id` int(11) DEFAULT NULL,
  `number` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_number_value_versions_on_number_value_id` (`number_value_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `number_value_versions`
--

LOCK TABLES `number_value_versions` WRITE;
/*!40000 ALTER TABLE `number_value_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `number_value_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `number_values`
--

DROP TABLE IF EXISTS `number_values`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `number_values` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `version` int(11) DEFAULT NULL,
  `version_creator_id` int(11) DEFAULT NULL,
  `number` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `number_values`
--

LOCK TABLES `number_values` WRITE;
/*!40000 ALTER TABLE `number_values` DISABLE KEYS */;
/*!40000 ALTER TABLE `number_values` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `oauth_sessions`
--

DROP TABLE IF EXISTS `oauth_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `oauth_sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `provider` varchar(255) DEFAULT NULL,
  `access_token` varchar(255) DEFAULT NULL,
  `refresh_token` varchar(255) DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_oauth_sessions_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `oauth_sessions`
--

LOCK TABLES `oauth_sessions` WRITE;
/*!40000 ALTER TABLE `oauth_sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `oauth_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `openbis_endpoints`
--

DROP TABLE IF EXISTS `openbis_endpoints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `openbis_endpoints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `as_endpoint` varchar(255) DEFAULT NULL,
  `space_perm_id` varchar(255) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `dss_endpoint` varchar(255) DEFAULT NULL,
  `web_endpoint` varchar(255) DEFAULT NULL,
  `refresh_period_mins` int(11) DEFAULT '120',
  `policy_id` int(11) DEFAULT NULL,
  `encrypted_password` varchar(255) DEFAULT NULL,
  `encrypted_password_iv` varchar(255) DEFAULT NULL,
  `meta_config_json` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `openbis_endpoints`
--

LOCK TABLES `openbis_endpoints` WRITE;
/*!40000 ALTER TABLE `openbis_endpoints` DISABLE KEYS */;
/*!40000 ALTER TABLE `openbis_endpoints` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organisms`
--

DROP TABLE IF EXISTS `organisms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `organisms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_letter` varchar(255) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organisms`
--

LOCK TABLES `organisms` WRITE;
/*!40000 ALTER TABLE `organisms` DISABLE KEYS */;
/*!40000 ALTER TABLE `organisms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organisms_projects`
--

DROP TABLE IF EXISTS `organisms_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `organisms_projects` (
  `organism_id` int(11) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  KEY `index_organisms_projects_on_organism_id_and_project_id` (`organism_id`,`project_id`),
  KEY `index_organisms_projects_on_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organisms_projects`
--

LOCK TABLES `organisms_projects` WRITE;
/*!40000 ALTER TABLE `organisms_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `organisms_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `people`
--

DROP TABLE IF EXISTS `people`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `people` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `skype_name` varchar(255) DEFAULT NULL,
  `web_page` varchar(255) DEFAULT NULL,
  `description` text,
  `avatar_id` int(11) DEFAULT NULL,
  `status_id` int(11) DEFAULT '0',
  `first_letter` varchar(10) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `roles_mask` int(11) DEFAULT '0',
  `orcid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `people`
--

LOCK TABLES `people` WRITE;
/*!40000 ALTER TABLE `people` DISABLE KEYS */;
INSERT INTO `people` VALUES (1,'2019-09-03 12:33:33','2019-09-03 12:33:33','Xiaoming','Hu','xiaoming.hu@h-its.org','+49 (0)6221–533–218','xiaoming.hu','https://www.h-its.org/de/','Software Developer',NULL,0,'H','f72a1c10-b074-0137-134b-721898481898',1,'https://orcid.org/0000-0001-9842-9718'),(2,'2019-09-03 12:37:39','2019-09-03 12:37:39','Antonio','Disanto','antonio.disanto@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'D','89fd7ac0-b075-0137-1348-721898481898',0,NULL),(3,'2019-09-03 12:37:39','2019-09-03 12:37:39','Nikos','Gianniotis','nikos.gianniotis@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','8a6b0ec0-b075-0137-1348-721898481898',0,NULL),(4,'2019-09-03 12:37:40','2019-09-03 12:37:40','Erica','Hopkins','erica.hopkins@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'H','8adf6550-b075-0137-1348-721898481898',0,NULL),(5,'2019-09-03 12:37:41','2019-09-03 12:37:41','Fenja','Kollasch','fenja.kollasch@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'K','8b629100-b075-0137-1348-721898481898',0,NULL),(6,'2019-09-03 12:37:42','2019-09-03 12:37:42','Markus','Nullmeier','markus.nullmeier@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'N','8bf55580-b075-0137-1348-721898481898',0,NULL),(7,'2019-09-03 12:37:43','2019-09-03 12:37:43','Kai','Polsterer','kai.polsterer@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'P','8c8f5840-b075-0137-1348-721898481898',0,NULL),(8,'2019-09-03 12:37:44','2019-09-03 12:37:44','Ganna','Gryn\'ova','ganna.grynova@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','8d3288d0-b075-0137-1348-721898481898',0,NULL),(9,'2019-09-03 12:37:45','2019-09-03 12:37:45','Pierre','Barbera','pierre.barbera@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'B','8d9bc990-b075-0137-1348-721898481898',0,NULL),(10,'2019-09-03 12:37:45','2019-09-03 12:37:45','Ben','Bettisworth','ben.bettisworth@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'B','8e051b60-b075-0137-1348-721898481898',0,NULL),(11,'2019-09-03 12:37:46','2019-09-03 12:37:46','Alexey','Kozlov','alexey.kozlov@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'K','8e795c10-b075-0137-1348-721898481898',0,NULL),(12,'2019-09-03 12:37:47','2019-09-03 12:37:47','Sarah','Lutteropp','sarah.lutteropp@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'L','8ef7aff0-b075-0137-1348-721898481898',0,NULL),(13,'2019-09-03 12:37:48','2019-09-03 12:37:48','Benoit','Morel','benoit.morel@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','8f814b20-b075-0137-1348-721898481898',0,NULL),(14,'2019-09-03 12:37:49','2019-09-03 12:37:49','Alexandros','Stamatakis','alexandros.stamatakis@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','901ff100-b075-0137-1348-721898481898',0,NULL),(15,'2019-09-03 12:37:50','2019-09-03 12:37:50','Johanna','Wegmann','johanna.wegmann@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','90beb840-b075-0137-1348-721898481898',0,NULL),(16,'2019-09-03 12:37:51','2019-09-03 12:37:51','Adrian','Zapletal','adrian.zapletal@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'Z','916a89f0-b075-0137-1348-721898481898',0,NULL),(17,'2019-09-03 12:37:52','2019-09-03 12:37:52','Timo','Dimitriadis','timo.dimitriadis@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'D','921e8670-b075-0137-1348-721898481898',0,NULL),(18,'2019-09-03 12:37:53','2019-09-03 12:37:53','Tilmann','Gneiting','tilmann.gneiting@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','928a4a00-b075-0137-1348-721898481898',0,NULL),(19,'2019-09-03 12:37:54','2019-09-03 12:37:54','Sebastian','Lerch','sebastian.lerch@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'L','93002150-b075-0137-1348-721898481898',0,NULL),(20,'2019-09-03 12:37:55','2019-09-03 12:37:55','Johannes','Resin','johannes.resin@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','937f9ed0-b075-0137-1348-721898481898',0,NULL),(21,'2019-09-03 12:37:56','2019-09-03 12:37:56','Patrick','Schmidt','patrick.schmidt@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','94130600-b075-0137-1348-721898481898',0,NULL),(22,'2019-09-03 12:37:57','2019-09-03 12:37:57','Eva-Maria','Walz','eva-maria.walz@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','94b7c480-b075-0137-1348-721898481898',0,NULL),(23,'2019-09-03 12:37:58','2019-09-03 12:37:58','Charlotte','Boys','charlotte.boys@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'B','95572c30-b075-0137-1348-721898481898',0,NULL),(24,'2019-09-03 12:37:58','2019-09-03 12:37:58','Philipp','Gerstner','philipp.gerstner@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','95c435a0-b075-0137-1348-721898481898',0,NULL),(25,'2019-09-03 12:37:59','2019-09-03 12:37:59','Vincent','Heuveline','vincent.heuveline@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'H','96394c00-b075-0137-1348-721898481898',0,NULL),(26,'2019-09-03 12:38:00','2019-09-03 12:38:00','Maximilian','Hoecker','maximilian.hoecker@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'H','96b987c0-b075-0137-1348-721898481898',0,NULL),(27,'2019-09-03 12:38:01','2019-09-03 12:38:01','Alejandra','Jayme','alejandra.jayme@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'J','974a0dd0-b075-0137-1348-721898481898',0,NULL),(28,'2019-09-03 12:38:02','2019-09-03 12:38:02','Sotirios','Nikas','sotirios.nikas@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'N','97df5540-b075-0137-1348-721898481898',0,NULL),(29,'2019-09-03 12:38:03','2019-09-03 12:38:03','Jonas','Roller','jonas.roller@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','987f2680-b075-0137-1348-721898481898',0,NULL),(30,'2019-09-03 12:38:04','2019-09-03 12:38:04','Chen','Song','chen.song@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','99317f10-b075-0137-1348-721898481898',0,NULL),(31,'2019-09-03 12:38:06','2019-09-03 12:38:06','Jonas','Beyrer','jonas.beyrer@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'B','9a0262e0-b075-0137-1348-721898481898',0,NULL),(32,'2019-09-03 12:38:06','2019-09-03 12:38:06','Clemens','Fruböse','clemens.fruboese@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'F','9a73f2e0-b075-0137-1348-721898481898',0,NULL),(33,'2019-09-03 12:38:07','2019-09-03 12:38:07','Mareike','Pfeil','mareike.pfeil@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'P','9aede6e0-b075-0137-1348-721898481898',0,NULL),(34,'2019-09-03 12:38:08','2019-09-03 12:38:08','Lukas','Sauer','lukas.sauer@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','9b6b9770-b075-0137-1348-721898481898',0,NULL),(35,'2019-09-03 12:38:09','2019-09-03 12:38:09','Florian','Stecker','florian.stecker@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','9bfc1710-b075-0137-1348-721898481898',0,NULL),(36,'2019-09-03 12:38:10','2019-09-03 12:38:10','Anna','Wienhard','anna.wienhard@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','9c926cd0-b075-0137-1348-721898481898',0,NULL),(37,'2019-09-03 12:38:11','2019-09-03 12:38:11','Menelaos','Zikidis','menelaos.zikidis@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'Z','9d30bcf0-b075-0137-1348-721898481898',0,NULL),(38,'2019-09-03 12:38:12','2019-09-03 12:38:12','Csaba','Daday','csaba.daday@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'D','9dcf16b0-b075-0137-1348-721898481898',0,NULL),(39,'2019-09-03 12:38:13','2019-09-03 12:38:13','Svenja','de Buhr','svenja.debuhr@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'D','9e3a3880-b075-0137-1348-721898481898',0,NULL),(40,'2019-09-03 12:38:13','2019-09-03 12:38:13','Krisztina','Feher','krisztina.feher@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'F','9eb379e0-b075-0137-1348-721898481898',0,NULL),(41,'2019-09-03 12:38:14','2019-09-03 12:38:14','Florian','Franz','florian.franz@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'F','9f379fa0-b075-0137-1348-721898481898',0,NULL),(42,'2019-09-03 12:38:15','2019-09-03 12:38:15','Frauke','Gräter','frauke.graeter@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','9fb9ab70-b075-0137-1348-721898481898',0,NULL),(43,'2019-09-03 12:38:16','2019-09-03 12:38:16','Ana','Herrera-Rodriguez','ana.herrera-rodriguez@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'H','a04cc110-b075-0137-1348-721898481898',0,NULL),(44,'2019-09-03 12:38:17','2019-09-03 12:38:17','Fan','Jin','fan.jin@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'J','a0f95d60-b075-0137-1348-721898481898',0,NULL),(45,'2019-09-03 12:38:18','2019-09-03 12:38:18','Markus','Kurth','markus.kurth@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'K','a1a4a930-b075-0137-1348-721898481898',0,NULL),(46,'2019-09-03 12:38:20','2019-09-03 12:38:20','Fabian','Kutzki','fabian.kutzki@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'K','a25456c0-b075-0137-1348-721898481898',0,NULL),(47,'2019-09-03 12:38:21','2019-09-03 12:38:21','Isabel','Martin','isabel.martin@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','a31888c0-b075-0137-1348-721898481898',0,NULL),(48,'2019-09-03 12:38:22','2019-09-03 12:38:22','Nicholas','Michelarakis','nicholas.michelarakis@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','a3e2d5e0-b075-0137-1348-721898481898',0,NULL),(49,'2019-09-03 12:38:23','2019-09-03 12:38:23','Agnieszka','Obarska-Kosinska','agnieszka.obarska@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'O','a4ae1640-b075-0137-1348-721898481898',0,NULL),(50,'2019-09-03 12:38:25','2019-09-03 12:38:25','Benedikt','Rennekamp','benedikt.rennekamp@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','a58d1730-b075-0137-1348-721898481898',0,NULL),(51,'2019-09-03 12:38:27','2019-09-03 12:38:27','Martin','Richter','martin.richter@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','a67e9830-b075-0137-1348-721898481898',0,NULL),(52,'2019-09-03 12:38:28','2019-09-03 12:38:28','Anna','Schröder','anna.schroeder@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','a7a7d640-b075-0137-1348-721898481898',0,NULL),(53,'2019-09-03 12:38:30','2019-09-03 12:38:30','Leon','Seeger','leon.seeger@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','a8b5ac20-b075-0137-1348-721898481898',0,NULL),(54,'2019-09-03 12:38:32','2019-09-03 12:38:32','Paula','Weidemüller','paula.weidemueller@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','a9c6fd80-b075-0137-1348-721898481898',0,NULL),(55,'2019-09-03 12:38:34','2019-09-03 12:38:34','Christopher','Zapp','christopher.zapp@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'Z','aae4a0c0-b075-0137-1348-721898481898',0,NULL),(56,'2019-09-03 12:38:36','2019-09-03 12:38:36','Lukas','Adam','lukas.adam@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'A','abfef7f0-b075-0137-1348-721898481898',0,NULL),(57,'2019-09-03 12:38:37','2019-09-03 12:38:37','Christina','Athanasiou','christina.athanasiou@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'A','ac742ca0-b075-0137-1348-721898481898',0,NULL),(58,'2019-09-03 12:38:37','2019-09-03 12:38:37','Daria','Kokh','daria.kokh@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'K','acf10cc0-b075-0137-1348-721898481898',0,NULL),(59,'2019-09-03 12:38:38','2019-09-03 12:38:38','Goutam','Mukherjee','goutam.mukherjee@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','ad79fbc0-b075-0137-1348-721898481898',0,NULL),(60,'2019-09-03 12:38:39','2019-09-03 12:38:39','Ariane','Nunes Alves','ariane.nunes-alves@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'N','ae0fe1b0-b075-0137-1348-721898481898',0,NULL),(61,'2019-09-03 12:38:40','2019-09-03 12:38:40','Stefan','Richter','stefan.richter@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','aeacb790-b075-0137-1348-721898481898',0,NULL),(62,'2019-09-03 12:38:41','2019-09-03 12:38:41','Daniel','Saar','daniel.saar@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','af5aeee0-b075-0137-1348-721898481898',0,NULL),(63,'2019-09-03 12:38:43','2019-09-03 12:38:43','Kashif','Sadiq','kashif.sadiq@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','b00e0dc0-b075-0137-1348-721898481898',0,NULL),(64,'2019-09-03 12:38:44','2019-09-03 12:38:44','Alexandros','Tsengenes','alexandros.tsengenes@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'T','b0d21180-b075-0137-1348-721898481898',0,NULL),(65,'2019-09-03 12:38:45','2019-09-03 12:38:45','Rebecca','Wade','rebecca.wade@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','b19c97d0-b075-0137-1348-721898481898',0,NULL),(66,'2019-09-03 12:38:47','2019-09-03 12:38:47','Nadia','Arslan','nadia.arslan@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'A','b26df6d0-b075-0137-1348-721898481898',0,NULL),(67,'2019-09-03 12:38:47','2019-09-03 12:38:47','Jason','Brockmeyer','jason.brockmeyer@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'B','b2da5860-b075-0137-1348-721898481898',0,NULL),(68,'2019-09-03 12:38:48','2019-09-03 12:38:48','Haixia','Chai','haixia.chai@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'C','b3510220-b075-0137-1348-721898481898',0,NULL),(69,'2019-09-03 12:38:49','2019-09-03 12:38:49','Fabian','Düker','fabian.dueker@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'D','b3d1a2f0-b075-0137-1348-721898481898',0,NULL),(70,'2019-09-03 12:38:50','2019-09-03 12:38:50','Mehwish','Fatima','mehwish.fatima@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'F','b465d5c0-b075-0137-1348-721898481898',0,NULL),(71,'2019-09-03 12:38:51','2019-09-03 12:38:51','Sungho','Jeon','sungho.jeon@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'J','b502f200-b075-0137-1348-721898481898',0,NULL),(72,'2019-09-03 12:38:52','2019-09-03 12:38:52','Federico','Lopez','federico.lopez@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'L','b5a8d190-b075-0137-1348-721898481898',0,NULL),(73,'2019-09-03 12:38:53','2019-09-03 12:38:53','Kevin','Mathews','kevin.mathews@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','b664a900-b075-0137-1348-721898481898',0,NULL),(74,'2019-09-03 12:38:54','2019-09-03 12:38:54','Mark-Christoph','Müller','mark-christoph.mueller@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','b71bbf40-b075-0137-1348-721898481898',0,NULL),(75,'2019-09-03 12:38:56','2019-09-03 12:38:56','Lucas','Rettenmeier','lucas.rettenmeier@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','b7e12620-b075-0137-1348-721898481898',0,NULL),(76,'2019-09-03 12:38:57','2019-09-03 12:38:57','Michael','Strube','michael.strube@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','b8ae6c00-b075-0137-1348-721898481898',0,NULL),(77,'2019-09-03 12:38:58','2019-09-03 12:38:58','Robert','Andrassy','robert.andrassy@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'A','b9828e70-b075-0137-1348-721898481898',0,NULL),(78,'2019-09-03 12:38:59','2019-09-03 12:38:59','David','Bubeck','david.bubeck@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'B','b9f72590-b075-0137-1348-721898481898',0,NULL),(79,'2019-09-03 12:39:00','2019-09-03 12:39:00','Sabrina','Gronow','sabrina.gronow@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','ba70f650-b075-0137-1348-721898481898',0,NULL),(80,'2019-09-03 12:39:01','2019-09-03 12:39:01','Leonhard','Horst','leonhard.horst@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'H','bafd94c0-b075-0137-1348-721898481898',0,NULL),(81,'2019-09-03 12:39:02','2019-09-03 12:39:02','Manuel','Kramer','manuel.kramer@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'K','bb941e10-b075-0137-1348-721898481898',0,NULL),(82,'2019-09-03 12:39:03','2019-09-03 12:39:03','Florian','Lach','florian.lach@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'L','bc351050-b075-0137-1348-721898481898',0,NULL),(83,'2019-09-03 12:39:04','2019-09-03 12:39:04','Melvin','Moreno','melvin.moreno@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','bcda3c80-b075-0137-1348-721898481898',0,NULL),(84,'2019-09-03 12:39:05','2019-09-03 12:39:05','Friedrich','Röpke','friedrich.roepke@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','bd903e30-b075-0137-1348-721898481898',0,NULL),(85,'2019-09-03 12:39:07','2019-09-03 12:39:07','Christian','Sand','christian.sand@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','be5879e0-b075-0137-1348-721898481898',0,NULL),(86,'2019-09-03 12:39:08','2019-09-03 12:39:08','Fabian','Schneider','fabian.schneider@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','bf1c4930-b075-0137-1348-721898481898',0,NULL),(87,'2019-09-03 12:39:09','2019-09-03 12:39:09','Theodoros','Soultanis','theodoros.soultanis@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','bfe1d810-b075-0137-1348-721898481898',0,NULL),(88,'2019-09-03 12:39:11','2019-09-03 12:39:11','Sucheta','Ghosh','sucheta.ghosh@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','c0bfd6d0-b075-0137-1348-721898481898',0,NULL),(89,'2019-09-03 12:39:11','2019-09-03 12:39:11','Martin','Golebiewski','martin.golebiewski@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','c1331cd0-b075-0137-1348-721898481898',0,NULL),(90,'2019-09-03 12:39:12','2019-09-03 12:39:12','Yachee','Gupta','yachee.gupta@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'G','c1b56d70-b075-0137-1348-721898481898',0,NULL),(91,'2019-09-03 12:39:13','2019-09-03 12:39:13','Olga','Krebs','olga.krebs@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'K','c2414dd0-b075-0137-1348-721898481898',0,NULL),(92,'2019-09-03 12:39:14','2019-09-03 12:39:14','Wolfgang','Müller','wolfgang.mueller@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'M','c2d1c3f0-b075-0137-1348-721898481898',0,NULL),(93,'2019-09-03 12:39:15','2019-09-03 12:39:15','Marcel','Petrov','marcel.petrov@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'P','c36f71a0-b075-0137-1348-721898481898',0,NULL),(94,'2019-09-03 12:39:16','2019-09-03 12:39:16','Ina','Pöhner','ina.poehner@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'P','c4182690-b075-0137-1348-721898481898',0,NULL),(95,'2019-09-03 12:39:17','2019-09-03 12:39:17','Maja','Rey','maja.rey@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'R','c4c2cbd0-b075-0137-1348-721898481898',0,NULL),(96,'2019-09-03 12:39:18','2019-09-03 12:39:18','Natalia','Simous','natalia.simous@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'S','c570ff20-b075-0137-1348-721898481898',0,NULL),(97,'2019-09-03 12:39:20','2019-09-03 12:39:20','Andreas','Weidemann','andreas.weidemann@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','c634b310-b075-0137-1348-721898481898',0,NULL),(98,'2019-09-03 12:39:21','2019-09-03 12:39:21','Benjamin','Winter','benjamin.winter@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','c6fae940-b075-0137-1348-721898481898',0,NULL),(99,'2019-09-03 12:39:23','2019-09-03 12:39:23','Ulrike','Wittig','ulrike.wittig@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'W','c7e29ce0-b075-0137-1348-721898481898',0,NULL),(100,'2019-09-03 12:39:24','2019-09-03 12:39:24','Dorotea','Dudas','dorotea.dudas@h-its.org',NULL,NULL,NULL,NULL,NULL,0,'D','c8ce7e80-b075-0137-1348-721898481898',0,NULL);
/*!40000 ALTER TABLE `people` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contributor_type` varchar(255) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `access_type` tinyint(4) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_permissions_on_policy_id` (`policy_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permissions`
--

LOCK TABLES `permissions` WRITE;
/*!40000 ALTER TABLE `permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `phenotypes`
--

DROP TABLE IF EXISTS `phenotypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `phenotypes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` text,
  `comment` text,
  `strain_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `phenotypes`
--

LOCK TABLES `phenotypes` WRITE;
/*!40000 ALTER TABLE `phenotypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `phenotypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `policies`
--

DROP TABLE IF EXISTS `policies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `policies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `sharing_scope` tinyint(4) DEFAULT NULL,
  `access_type` tinyint(4) DEFAULT NULL,
  `use_whitelist` tinyint(1) DEFAULT NULL,
  `use_blacklist` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `policies`
--

LOCK TABLES `policies` WRITE;
/*!40000 ALTER TABLE `policies` DISABLE KEYS */;
/*!40000 ALTER TABLE `policies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `presentation_auth_lookup`
--

DROP TABLE IF EXISTS `presentation_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `presentation_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_presentation_user_id_asset_id_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_presentation_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `presentation_auth_lookup`
--

LOCK TABLES `presentation_auth_lookup` WRITE;
/*!40000 ALTER TABLE `presentation_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `presentation_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `presentation_versions`
--

DROP TABLE IF EXISTS `presentation_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `presentation_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `presentation_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `revision_comments` text,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `presentation_versions`
--

LOCK TABLES `presentation_versions` WRITE;
/*!40000 ALTER TABLE `presentation_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `presentation_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `presentation_versions_projects`
--

DROP TABLE IF EXISTS `presentation_versions_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `presentation_versions_projects` (
  `project_id` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `presentation_versions_projects`
--

LOCK TABLES `presentation_versions_projects` WRITE;
/*!40000 ALTER TABLE `presentation_versions_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `presentation_versions_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `presentations`
--

DROP TABLE IF EXISTS `presentations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `presentations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `version` int(11) DEFAULT '1',
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `presentations`
--

LOCK TABLES `presentations` WRITE;
/*!40000 ALTER TABLE `presentations` DISABLE KEYS */;
/*!40000 ALTER TABLE `presentations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `presentations_projects`
--

DROP TABLE IF EXISTS `presentations_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `presentations_projects` (
  `project_id` int(11) DEFAULT NULL,
  `presentation_id` int(11) DEFAULT NULL,
  KEY `index_presentations_projects_pres_proj_id` (`presentation_id`,`project_id`),
  KEY `index_presentations_projects_on_project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `presentations_projects`
--

LOCK TABLES `presentations_projects` WRITE;
/*!40000 ALTER TABLE `presentations_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `presentations_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `programmes`
--

DROP TABLE IF EXISTS `programmes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `programmes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `avatar_id` int(11) DEFAULT NULL,
  `web_page` varchar(255) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `funding_details` text,
  `is_activated` tinyint(1) DEFAULT '0',
  `activation_rejection_reason` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `programmes`
--

LOCK TABLES `programmes` WRITE;
/*!40000 ALTER TABLE `programmes` DISABLE KEYS */;
/*!40000 ALTER TABLE `programmes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_descendants`
--

DROP TABLE IF EXISTS `project_descendants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_descendants` (
  `ancestor_id` int(11) DEFAULT NULL,
  `descendant_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_descendants`
--

LOCK TABLES `project_descendants` WRITE;
/*!40000 ALTER TABLE `project_descendants` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_descendants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_folder_assets`
--

DROP TABLE IF EXISTS `project_folder_assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_folder_assets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `asset_id` int(11) DEFAULT NULL,
  `asset_type` varchar(255) DEFAULT NULL,
  `project_folder_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_folder_assets`
--

LOCK TABLES `project_folder_assets` WRITE;
/*!40000 ALTER TABLE `project_folder_assets` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_folder_assets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_folders`
--

DROP TABLE IF EXISTS `project_folders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_folders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `parent_id` int(11) DEFAULT NULL,
  `editable` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `incoming` tinyint(1) DEFAULT '0',
  `deletable` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_folders`
--

LOCK TABLES `project_folders` WRITE;
/*!40000 ALTER TABLE `project_folders` DISABLE KEYS */;
/*!40000 ALTER TABLE `project_folders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_positions`
--

DROP TABLE IF EXISTS `project_positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_positions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_positions`
--

LOCK TABLES `project_positions` WRITE;
/*!40000 ALTER TABLE `project_positions` DISABLE KEYS */;
INSERT INTO `project_positions` VALUES (2,'Vice Coordinator','2019-09-03 12:32:49','2019-09-03 12:32:49'),(3,'Project Coordinator','2019-09-03 12:32:49','2019-09-03 12:32:49'),(4,'Student','2019-09-03 12:32:49','2019-09-03 12:32:49'),(5,'Postdoc','2019-09-03 12:32:49','2019-09-03 12:32:49'),(7,'Technician','2019-09-03 12:32:49','2019-09-03 12:32:49'),(8,'PhD Student','2019-09-03 12:32:49','2019-09-03 12:32:49');
/*!40000 ALTER TABLE `project_positions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `project_subscriptions`
--

DROP TABLE IF EXISTS `project_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `project_subscriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  `unsubscribed_types` varchar(255) DEFAULT NULL,
  `frequency` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_project_subscriptions_on_person_id_and_project_id` (`person_id`,`project_id`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_subscriptions`
--

LOCK TABLES `project_subscriptions` WRITE;
/*!40000 ALTER TABLE `project_subscriptions` DISABLE KEYS */;
INSERT INTO `project_subscriptions` VALUES (1,1,2,'--- []\n','weekly'),(2,1,1,'--- []\n','weekly'),(3,1,3,'--- []\n','weekly'),(4,1,4,'--- []\n','weekly'),(5,1,5,'--- []\n','weekly'),(6,1,6,'--- []\n','weekly'),(7,1,7,'--- []\n','weekly'),(8,1,8,'--- []\n','weekly'),(9,1,9,'--- []\n','weekly'),(10,1,10,'--- []\n','weekly'),(11,1,11,'--- []\n','weekly'),(12,1,12,'--- []\n','weekly'),(13,2,3,'--- []\n','weekly'),(14,3,3,'--- []\n','weekly'),(15,4,3,'--- []\n','weekly'),(16,5,3,'--- []\n','weekly'),(17,6,3,'--- []\n','weekly'),(18,7,3,'--- []\n','weekly'),(19,8,4,'--- []\n','weekly'),(20,9,5,'--- []\n','weekly'),(21,10,5,'--- []\n','weekly'),(22,11,5,'--- []\n','weekly'),(23,12,5,'--- []\n','weekly'),(24,13,5,'--- []\n','weekly'),(25,14,5,'--- []\n','weekly'),(26,15,5,'--- []\n','weekly'),(27,16,5,'--- []\n','weekly'),(28,17,6,'--- []\n','weekly'),(29,18,6,'--- []\n','weekly'),(30,19,6,'--- []\n','weekly'),(31,20,6,'--- []\n','weekly'),(32,21,6,'--- []\n','weekly'),(33,22,6,'--- []\n','weekly'),(34,23,7,'--- []\n','weekly'),(35,24,7,'--- []\n','weekly'),(36,25,7,'--- []\n','weekly'),(37,26,7,'--- []\n','weekly'),(38,27,7,'--- []\n','weekly'),(39,28,7,'--- []\n','weekly'),(40,29,7,'--- []\n','weekly'),(41,30,7,'--- []\n','weekly'),(42,31,8,'--- []\n','weekly'),(43,32,8,'--- []\n','weekly'),(44,33,8,'--- []\n','weekly'),(45,34,8,'--- []\n','weekly'),(46,35,8,'--- []\n','weekly'),(47,36,8,'--- []\n','weekly'),(48,37,8,'--- []\n','weekly'),(49,38,9,'--- []\n','weekly'),(50,39,9,'--- []\n','weekly'),(51,40,9,'--- []\n','weekly'),(52,41,9,'--- []\n','weekly'),(53,42,9,'--- []\n','weekly'),(54,43,9,'--- []\n','weekly'),(55,44,9,'--- []\n','weekly'),(56,45,9,'--- []\n','weekly'),(57,46,9,'--- []\n','weekly'),(58,47,9,'--- []\n','weekly'),(59,48,9,'--- []\n','weekly'),(60,49,9,'--- []\n','weekly'),(61,50,9,'--- []\n','weekly'),(62,51,9,'--- []\n','weekly'),(63,52,9,'--- []\n','weekly'),(64,53,9,'--- []\n','weekly'),(65,54,9,'--- []\n','weekly'),(66,55,9,'--- []\n','weekly'),(67,56,10,'--- []\n','weekly'),(68,57,10,'--- []\n','weekly'),(69,58,10,'--- []\n','weekly'),(70,59,10,'--- []\n','weekly'),(71,60,10,'--- []\n','weekly'),(72,61,10,'--- []\n','weekly'),(73,62,10,'--- []\n','weekly'),(74,63,10,'--- []\n','weekly'),(75,64,10,'--- []\n','weekly'),(76,65,10,'--- []\n','weekly'),(77,66,11,'--- []\n','weekly'),(78,67,11,'--- []\n','weekly'),(79,68,11,'--- []\n','weekly'),(80,69,11,'--- []\n','weekly'),(81,70,11,'--- []\n','weekly'),(82,71,11,'--- []\n','weekly'),(83,72,11,'--- []\n','weekly'),(84,73,11,'--- []\n','weekly'),(85,74,11,'--- []\n','weekly'),(86,75,11,'--- []\n','weekly'),(87,76,11,'--- []\n','weekly'),(88,77,12,'--- []\n','weekly'),(89,78,12,'--- []\n','weekly'),(90,79,12,'--- []\n','weekly'),(91,80,12,'--- []\n','weekly'),(92,81,12,'--- []\n','weekly'),(93,82,12,'--- []\n','weekly'),(94,83,12,'--- []\n','weekly'),(95,84,12,'--- []\n','weekly'),(96,85,12,'--- []\n','weekly'),(97,86,12,'--- []\n','weekly'),(98,87,12,'--- []\n','weekly'),(99,88,2,'--- []\n','weekly'),(100,89,2,'--- []\n','weekly'),(101,90,2,'--- []\n','weekly'),(102,91,2,'--- []\n','weekly'),(103,92,2,'--- []\n','weekly'),(104,93,2,'--- []\n','weekly'),(105,94,2,'--- []\n','weekly'),(106,95,2,'--- []\n','weekly'),(107,96,2,'--- []\n','weekly'),(108,97,2,'--- []\n','weekly'),(109,98,2,'--- []\n','weekly'),(110,99,2,'--- []\n','weekly'),(111,100,2,'--- []\n','weekly');
/*!40000 ALTER TABLE `project_subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `web_page` varchar(255) DEFAULT NULL,
  `wiki_page` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `description` text,
  `avatar_id` int(11) DEFAULT NULL,
  `default_policy_id` int(11) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `site_credentials` varchar(255) DEFAULT NULL,
  `site_root_uri` varchar(255) DEFAULT NULL,
  `last_jerm_run` datetime DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `programme_id` int(11) DEFAULT NULL,
  `ancestor_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `default_license` varchar(255) DEFAULT 'CC-BY-4.0',
  `use_default_policy` tinyint(1) DEFAULT '0',
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects`
--

LOCK TABLES `projects` WRITE;
/*!40000 ALTER TABLE `projects` DISABLE KEYS */;
INSERT INTO `projects` VALUES (1,'Default Project',NULL,NULL,'2019-09-03 12:32:51','2019-09-03 12:33:32',NULL,NULL,NULL,'D',NULL,NULL,NULL,'dea41020-b074-0137-134a-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(2,'Scientific Databases and Visualization','https://www.h-its.org/research/sdbv/',NULL,'2019-09-03 12:33:32','2019-09-03 12:39:25','Our mission is to improve data storage and the search for life science data, making storage, search, and processing simple to use for domain experts who are not computer scientists. We believe that much can be learned from running actual systems and serving their users, who can then tell us what is important for them.',NULL,NULL,'S',NULL,NULL,NULL,'f6e09320-b074-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(3,'Astroinformatics','https://www.h-its.org/research/ain/',NULL,'2019-09-03 12:34:38','2019-09-03 12:37:44','The AIN group develops new methods and tools to deal with the exponentially increasing amount of data in astronomy.',NULL,NULL,'A',NULL,NULL,NULL,'1e0d6c90-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(4,'Computational Carbon Chemistry','https://www.h-its.org/research/ccc/',NULL,'2019-09-03 12:34:46','2019-09-03 12:37:44','The CCC group uses state-of-the-art computational chemistry to explore and exploit diverse functional organic materials.',NULL,NULL,'C',NULL,NULL,NULL,'22ffcd90-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(5,'Computational Molecular Evolution','https://www.h-its.org/research/cme/',NULL,'2019-09-03 12:34:52','2019-09-03 12:37:52','The Computational Molecular Evolution (CME) group focuses on developing algorithms, computer architectures, and high-performance computing solutions for bioinformatics.',NULL,NULL,'C',NULL,NULL,NULL,'268003c0-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(6,'Computational Statistics','https://www.h-its.org/research/cst/',NULL,'2019-09-03 12:34:58','2019-09-03 12:37:57','The group’s current focus is on probabilistic forecasting.',NULL,NULL,'C',NULL,NULL,NULL,'2a462fd0-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(7,'Data Mining and Uncertainty Quantification','https://www.h-its.org/research/dmq/',NULL,'2019-09-03 12:35:07','2019-09-03 12:38:05','In this group we make use of stochastic mathematical models, high-performance computing, and hardware-aware computing to quantify the impact of uncertainties in large data sets and/or associated mathematical models and thus help to establish reliable insights in data mining. Currently, the fields of application are medical engineering, biology, and meteorology.',NULL,NULL,'D',NULL,NULL,NULL,'2f67ed70-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(8,'Groups and Geometry','https://www.h-its.org/research/grg/',NULL,'2019-09-03 12:35:48','2019-09-03 12:38:11','The research group “Groups and Geometry” investigates various mathematical problems in the fields of geometry and topology, which involve the interplay between geometric spaces, such as Riemannian manifolds or metric spaces, and groups, arising for example from symmetries, acting on them.',NULL,NULL,'G',NULL,NULL,NULL,'47c40990-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(9,'Molecular Biomechanics','https://www.h-its.org/research/mbm/',NULL,'2019-09-03 12:35:54','2019-09-03 12:38:35','The major interest of the Molecular Biomechanics group is to decipher how proteins have been designed to specifically respond to mechanical forces in the cellular environment or as a biomaterial.s',NULL,NULL,'M',NULL,NULL,NULL,'4b586340-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(10,'Molecular and Cellular Modeling','https://www.h-its.org/research/mcm/',NULL,'2019-09-03 12:36:05','2019-09-03 12:38:46','In the MCM group we are primarily interested in understanding how biomolecules interact.',NULL,NULL,'M',NULL,NULL,NULL,'52104c80-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(11,'Natural Language Processing','https://www.h-its.org/research/nlp/',NULL,'2019-09-03 12:36:12','2019-09-03 12:38:58','The Natural Language Processing (NLP) group develops methods, algorithms, and tools for the automatic analysis of natural language.',NULL,NULL,'N',NULL,NULL,NULL,'5677d680-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(12,'Physics of Stellar Objects','https://www.h-its.org/research/pso/',NULL,'2019-09-03 12:36:16','2019-09-03 12:39:10','Our research group “Physics of Stellar Objects” seeks to understand the processes in stars and stellar explosions based on extensive numerical simulations.',NULL,NULL,'P',NULL,NULL,NULL,'58fb47e0-b075-0137-134b-721898481898',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL);
/*!40000 ALTER TABLE `projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_publications`
--

DROP TABLE IF EXISTS `projects_publications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_publications` (
  `project_id` int(11) DEFAULT NULL,
  `publication_id` int(11) DEFAULT NULL,
  KEY `index_projects_publications_on_project_id` (`project_id`),
  KEY `index_projects_publications_on_publication_id_and_project_id` (`publication_id`,`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_publications`
--

LOCK TABLES `projects_publications` WRITE;
/*!40000 ALTER TABLE `projects_publications` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_publications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_sample_types`
--

DROP TABLE IF EXISTS `projects_sample_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_sample_types` (
  `project_id` int(11) DEFAULT NULL,
  `sample_type_id` int(11) DEFAULT NULL,
  KEY `index_projects_sample_types_on_project_id` (`project_id`),
  KEY `index_projects_sample_types_on_sample_type_id_and_project_id` (`sample_type_id`,`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_sample_types`
--

LOCK TABLES `projects_sample_types` WRITE;
/*!40000 ALTER TABLE `projects_sample_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_sample_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_samples`
--

DROP TABLE IF EXISTS `projects_samples`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_samples` (
  `project_id` int(11) DEFAULT NULL,
  `sample_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_samples`
--

LOCK TABLES `projects_samples` WRITE;
/*!40000 ALTER TABLE `projects_samples` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_samples` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_sop_versions`
--

DROP TABLE IF EXISTS `projects_sop_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_sop_versions` (
  `project_id` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_sop_versions`
--

LOCK TABLES `projects_sop_versions` WRITE;
/*!40000 ALTER TABLE `projects_sop_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_sop_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_sops`
--

DROP TABLE IF EXISTS `projects_sops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_sops` (
  `project_id` int(11) DEFAULT NULL,
  `sop_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_sops`
--

LOCK TABLES `projects_sops` WRITE;
/*!40000 ALTER TABLE `projects_sops` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_sops` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_strains`
--

DROP TABLE IF EXISTS `projects_strains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_strains` (
  `project_id` int(11) DEFAULT NULL,
  `strain_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_strains`
--

LOCK TABLES `projects_strains` WRITE;
/*!40000 ALTER TABLE `projects_strains` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_strains` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_workflow_versions`
--

DROP TABLE IF EXISTS `projects_workflow_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_workflow_versions` (
  `project_id` int(11) DEFAULT NULL,
  `version_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_workflow_versions`
--

LOCK TABLES `projects_workflow_versions` WRITE;
/*!40000 ALTER TABLE `projects_workflow_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_workflow_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects_workflows`
--

DROP TABLE IF EXISTS `projects_workflows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects_workflows` (
  `project_id` int(11) DEFAULT NULL,
  `workflow_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects_workflows`
--

LOCK TABLES `projects_workflows` WRITE;
/*!40000 ALTER TABLE `projects_workflows` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects_workflows` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `publication_auth_lookup`
--

DROP TABLE IF EXISTS `publication_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publication_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_pub_user_id_asset_id_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_publication_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publication_auth_lookup`
--

LOCK TABLES `publication_auth_lookup` WRITE;
/*!40000 ALTER TABLE `publication_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `publication_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `publication_authors`
--

DROP TABLE IF EXISTS `publication_authors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publication_authors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `publication_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `author_index` int(11) DEFAULT NULL,
  `person_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publication_authors`
--

LOCK TABLES `publication_authors` WRITE;
/*!40000 ALTER TABLE `publication_authors` DISABLE KEYS */;
/*!40000 ALTER TABLE `publication_authors` ENABLE KEYS */;
UNLOCK TABLES;

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

--
-- Table structure for table `publications`
--

DROP TABLE IF EXISTS `publications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pubmed_id` int(11) DEFAULT NULL,
  `title` text,
  `abstract` text,
  `published_date` date DEFAULT NULL,
  `journal` varchar(255) DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `citation` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  `registered_mode` int(11) DEFAULT NULL,
  `booktitle` varchar(255) DEFAULT NULL,
  `publisher` varchar(255) DEFAULT NULL,
  `editor` varchar(255) DEFAULT NULL,
  `publication_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_publications_on_contributor` (`contributor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publications`
--

LOCK TABLES `publications` WRITE;
/*!40000 ALTER TABLE `publications` DISABLE KEYS */;
/*!40000 ALTER TABLE `publications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recommended_model_environments`
--

DROP TABLE IF EXISTS `recommended_model_environments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recommended_model_environments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1032857502 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recommended_model_environments`
--

LOCK TABLES `recommended_model_environments` WRITE;
/*!40000 ALTER TABLE `recommended_model_environments` DISABLE KEYS */;
INSERT INTO `recommended_model_environments` VALUES (54709254,'CPLEX Interactive Optimizer','2019-09-03 12:32:48','2019-09-03 12:32:48'),(56444055,'PathwayLab','2019-09-03 12:32:48','2019-09-03 12:32:48'),(76516951,'CellSys','2019-09-03 12:32:48','2019-09-03 12:32:48'),(104000749,'Insilico Discovery','2019-09-03 12:32:48','2019-09-03 12:32:48'),(114118389,'Gromacs','2019-09-03 12:32:48','2019-09-03 12:32:48'),(134358931,'Python Simulator for Cellular Systems (PySCeS)','2019-09-03 12:32:48','2019-09-03 12:32:48'),(275853935,'Jarnac (Systems Biology Workbench)','2019-09-03 12:32:48','2019-09-03 12:32:48'),(456178890,'Matlab','2019-09-03 12:32:48','2019-09-03 12:32:48'),(467843593,'PK-Sim','2019-09-03 12:32:48','2019-09-03 12:32:48'),(504770172,'PottersWheel','2019-09-03 12:32:48','2019-09-03 12:32:48'),(529642631,'MeVisLab','2019-09-03 12:32:48','2019-09-03 12:32:48'),(580179347,'CellDesigner (SBML ODE Solver)','2019-09-03 12:32:48','2019-09-03 12:32:48'),(729931928,'CellNetAnalyzer','2019-09-03 12:32:48','2019-09-03 12:32:48'),(757561406,'Virtual Cell','2019-09-03 12:32:48','2019-09-03 12:32:48'),(830560120,'Systems Biology Toolbox 2','2019-09-03 12:32:48','2019-09-03 12:32:48'),(857727606,'JWS Online','2019-09-03 12:32:48','2019-09-03 12:32:48'),(915852937,'Copasi','2019-09-03 12:32:48','2019-09-03 12:32:48'),(949170268,'XPP-Aut','2019-09-03 12:32:48','2019-09-03 12:32:48'),(951528555,'Mathematica','2019-09-03 12:32:48','2019-09-03 12:32:48'),(968724970,'roadrunner (Systems Biology Workbench)','2019-09-03 12:32:48','2019-09-03 12:32:48'),(999460246,'AUTO2000','2019-09-03 12:32:48','2019-09-03 12:32:48'),(1032857501,'MoBi','2019-09-03 12:32:48','2019-09-03 12:32:48');
/*!40000 ALTER TABLE `recommended_model_environments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reindexing_queues`
--

DROP TABLE IF EXISTS `reindexing_queues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reindexing_queues` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_type` varchar(255) DEFAULT NULL,
  `item_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reindexing_queues`
--

LOCK TABLES `reindexing_queues` WRITE;
/*!40000 ALTER TABLE `reindexing_queues` DISABLE KEYS */;
/*!40000 ALTER TABLE `reindexing_queues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `relationship_types`
--

DROP TABLE IF EXISTS `relationship_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `relationship_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `key` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `relationship_types`
--

LOCK TABLES `relationship_types` WRITE;
/*!40000 ALTER TABLE `relationship_types` DISABLE KEYS */;
INSERT INTO `relationship_types` VALUES (1,'Construction data','Data used for model testing','2019-09-03 12:32:53','2019-09-03 12:32:53','CONSTRUCTION'),(2,'Validation data','Data used for validating a model','2019-09-03 12:32:53','2019-09-03 12:32:53','VALIDATION'),(3,'Simulation results','Data resulting from running a model simulation','2019-09-03 12:32:53','2019-09-03 12:32:53','SIMULATION');
/*!40000 ALTER TABLE `relationship_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `relationships`
--

DROP TABLE IF EXISTS `relationships`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `relationships` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject_type` varchar(255) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `predicate` varchar(255) NOT NULL,
  `other_object_type` varchar(255) NOT NULL,
  `other_object_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `relationships`
--

LOCK TABLES `relationships` WRITE;
/*!40000 ALTER TABLE `relationships` DISABLE KEYS */;
/*!40000 ALTER TABLE `relationships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource_publish_logs`
--

DROP TABLE IF EXISTS `resource_publish_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_publish_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `resource_type` varchar(255) DEFAULT NULL,
  `resource_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `publish_state` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `comment` text,
  PRIMARY KEY (`id`),
  KEY `index_resource_publish_logs_on_publish_state` (`publish_state`),
  KEY `index_resource_publish_logs_on_resource_type_and_resource_id` (`resource_type`,`resource_id`),
  KEY `index_resource_publish_logs_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource_publish_logs`
--

LOCK TABLES `resource_publish_logs` WRITE;
/*!40000 ALTER TABLE `resource_publish_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `resource_publish_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample_attribute_types`
--

DROP TABLE IF EXISTS `sample_attribute_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample_attribute_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `base_type` varchar(255) DEFAULT NULL,
  `regexp` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `placeholder` varchar(255) DEFAULT NULL,
  `description` text,
  `resolution` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample_attribute_types`
--

LOCK TABLES `sample_attribute_types` WRITE;
/*!40000 ALTER TABLE `sample_attribute_types` DISABLE KEYS */;
INSERT INTO `sample_attribute_types` VALUES (1,'Date time','DateTime','.*','2019-09-03 12:32:53','2019-09-03 12:32:53','January 1, 2015 11:30 AM',NULL,NULL),(2,'Date','Date','.*','2019-09-03 12:32:53','2019-09-03 12:32:53','January 1, 2015',NULL,NULL),(3,'Real number','Float','.*','2019-09-03 12:32:53','2019-09-03 12:32:53','3.6',NULL,NULL),(4,'Integer','Integer','.*','2019-09-03 12:32:53','2019-09-03 12:32:53','1',NULL,NULL),(5,'Web link','String','(?x-mi:(?=(?-mix:http|https):)\n        ([a-zA-Z][\\-+.a-zA-Z\\d]*):                           (?# 1: scheme)\n        (?:\n           ((?:[\\-_.!~*\'()a-zA-Z\\d;?:@&=+$,]|%[a-fA-F\\d]{2})(?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*)                    (?# 2: opaque)\n        |\n           (?:(?:\n             \\/\\/(?:\n                 (?:(?:((?:[\\-_.!~*\'()a-zA-Z\\d;:&=+$,]|%[a-fA-F\\d]{2})*)@)?        (?# 3: userinfo)\n                   (?:((?:(?:[a-zA-Z0-9\\-.]|%\\h\\h)+|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}|\\[(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})|(?:(?:[a-fA-F\\d]{1,4}:)*[a-fA-F\\d]{1,4})?::(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}))?)\\]))(?::(\\d*))?))? (?# 4: host, 5: port)\n               |\n                 ((?:[\\-_.!~*\'()a-zA-Z\\d$,;:@&=+]|%[a-fA-F\\d]{2})+)                 (?# 6: registry)\n               )\n             |\n             (?!\\/\\/))                           (?# XXX: \'\\/\\/\' is the mark for hostport)\n             (\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*(?:\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*)*)?                    (?# 7: path)\n           )(?:\\?((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                 (?# 8: query)\n        )\n        (?:\\#((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                  (?# 9: fragment)\n      )','2019-09-03 12:32:53','2019-09-03 12:32:53','http://www.example.com',NULL,'\\0'),(6,'Email address','String','(?-mix:\\A(?:[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\u00ff]+|\\x22(?:[^\\x0d\\x22\\x5c\\u0080-\\u00ff]|\\x5c[\\x00-\\x7f])*\\x22)(?:\\x2e(?:[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\u00ff]+|\\x22(?:[^\\x0d\\x22\\x5c\\u0080-\\u00ff]|\\x5c[\\x00-\\x7f])*\\x22))*\\x40(?:(?:(?:[a-zA-Z\\d](?:[-a-zA-Z\\d]*[a-zA-Z\\d])?)\\.)*(?:[a-zA-Z](?:[-a-zA-Z\\d]*[a-zA-Z\\d])?)\\.?)?[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\u00ff]+\\z)','2019-09-03 12:32:53','2019-09-03 12:32:53','someone@example.com',NULL,'mailto:\\0'),(7,'Text','Text','.*','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,NULL),(8,'String','String','.*','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,NULL),(9,'ChEBI','String','^CHEBI:\\d+$','2019-09-03 12:32:53','2019-09-03 12:32:53','CHEBI:1234',NULL,'http://identifiers.org/chebi/\\0'),(10,'ECN','String','[0-9\\.]+','2019-09-03 12:32:53','2019-09-03 12:32:53','2.7.1.121',NULL,'http://identifiers.org/brenda/\\0'),(11,'MetaNetX chemical','String','MNXM\\d+','2019-09-03 12:32:53','2019-09-03 12:32:53','MNXM01',NULL,'http://identifiers.org/metanetx.chemical/\\0'),(12,'MetaNetX reaction','String','MNXR\\d+','2019-09-03 12:32:53','2019-09-03 12:32:53','MNXR891',NULL,'http://identifiers.org/metanetx.reaction/\\0'),(13,'MetaNetX compartment','String','MNX[CD]\\d+','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,'http://identifiers.org/metanetx.compartment/\\0'),(14,'InChI','String','^InChI\\=1S?\\/[A-Za-z0-9\\.]+(\\+[0-9]+)?(\\/[cnpqbtmsih][A-Za-z0-9\\-\\+\\(\\)\\,\\/\\?\\;\\.]+)*$','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,'http://identifiers.org/inchi/\\0'),(15,'Boolean','Boolean','.*','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,NULL),(16,'SEEK Strain','SeekStrain','.*','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,NULL),(17,'SEEK Sample','SeekSample','.*','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,NULL),(18,'Controlled Vocabulary','CV','.*','2019-09-03 12:32:53','2019-09-03 12:32:53',NULL,NULL,NULL),(19,'URI','String','(?x-mi:\n        ([a-zA-Z][\\-+.a-zA-Z\\d]*):                           (?# 1: scheme)\n        (?:\n           ((?:[\\-_.!~*\'()a-zA-Z\\d;?:@&=+$,]|%[a-fA-F\\d]{2})(?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*)                    (?# 2: opaque)\n        |\n           (?:(?:\n             \\/\\/(?:\n                 (?:(?:((?:[\\-_.!~*\'()a-zA-Z\\d;:&=+$,]|%[a-fA-F\\d]{2})*)@)?        (?# 3: userinfo)\n                   (?:((?:(?:[a-zA-Z0-9\\-.]|%\\h\\h)+|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}|\\[(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})|(?:(?:[a-fA-F\\d]{1,4}:)*[a-fA-F\\d]{1,4})?::(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}))?)\\]))(?::(\\d*))?))? (?# 4: host, 5: port)\n               |\n                 ((?:[\\-_.!~*\'()a-zA-Z\\d$,;:@&=+]|%[a-fA-F\\d]{2})+)                 (?# 6: registry)\n               )\n             |\n             (?!\\/\\/))                           (?# XXX: \'\\/\\/\' is the mark for hostport)\n             (\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*(?:\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*)*)?                    (?# 7: path)\n           )(?:\\?((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                 (?# 8: query)\n        )\n        (?:\\#((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                  (?# 9: fragment)\n      )','2019-09-03 12:32:53','2019-09-03 12:32:53','http://www.example.com/123',NULL,'\\0'),(20,'DOI','String','(DOI:)?(.*)','2019-09-03 12:32:53','2019-09-03 12:32:53','DOI:10.1109/5.771073',NULL,'https://doi.org/\\2'),(21,'NCBI ID','String','[0-9]+','2019-09-03 12:32:53','2019-09-03 12:32:53','23234',NULL,'https://identifiers.org/taxonomy/\\0');
/*!40000 ALTER TABLE `sample_attribute_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample_attributes`
--

DROP TABLE IF EXISTS `sample_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample_attributes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `sample_attribute_type_id` int(11) DEFAULT NULL,
  `required` tinyint(1) DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `pos` int(11) DEFAULT NULL,
  `sample_type_id` int(11) DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `is_title` tinyint(1) DEFAULT '0',
  `template_column_index` int(11) DEFAULT NULL,
  `accessor_name` varchar(255) DEFAULT NULL,
  `sample_controlled_vocab_id` int(11) DEFAULT NULL,
  `linked_sample_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sample_attributes_on_sample_type_id` (`sample_type_id`),
  KEY `index_sample_attributes_on_unit_id` (`unit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample_attributes`
--

LOCK TABLES `sample_attributes` WRITE;
/*!40000 ALTER TABLE `sample_attributes` DISABLE KEYS */;
/*!40000 ALTER TABLE `sample_attributes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample_auth_lookup`
--

DROP TABLE IF EXISTS `sample_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_sample_user_id_asset_id_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_sample_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample_auth_lookup`
--

LOCK TABLES `sample_auth_lookup` WRITE;
/*!40000 ALTER TABLE `sample_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `sample_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample_controlled_vocab_terms`
--

DROP TABLE IF EXISTS `sample_controlled_vocab_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample_controlled_vocab_terms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) DEFAULT NULL,
  `sample_controlled_vocab_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample_controlled_vocab_terms`
--

LOCK TABLES `sample_controlled_vocab_terms` WRITE;
/*!40000 ALTER TABLE `sample_controlled_vocab_terms` DISABLE KEYS */;
INSERT INTO `sample_controlled_vocab_terms` VALUES (1,'batch',1,'2019-09-03 12:32:53','2019-09-03 12:32:53'),(2,'chemostat',1,'2019-09-03 12:32:53','2019-09-03 12:32:53'),(3,'Whole cell',2,'2019-09-03 12:32:53','2019-09-03 12:32:53'),(4,'Membrane fraction',2,'2019-09-03 12:32:53','2019-09-03 12:32:53');
/*!40000 ALTER TABLE `sample_controlled_vocab_terms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample_controlled_vocabs`
--

DROP TABLE IF EXISTS `sample_controlled_vocabs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample_controlled_vocabs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample_controlled_vocabs`
--

LOCK TABLES `sample_controlled_vocabs` WRITE;
/*!40000 ALTER TABLE `sample_controlled_vocabs` DISABLE KEYS */;
INSERT INTO `sample_controlled_vocabs` VALUES (1,'SysMO Cell Culture Growth Type',NULL,'2019-09-03 12:32:53','2019-09-03 12:32:53','S'),(2,'SysMO Sample Organism Part',NULL,'2019-09-03 12:32:53','2019-09-03 12:32:53','S');
/*!40000 ALTER TABLE `sample_controlled_vocabs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample_resource_links`
--

DROP TABLE IF EXISTS `sample_resource_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample_resource_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sample_id` int(11) DEFAULT NULL,
  `resource_id` int(11) DEFAULT NULL,
  `resource_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sample_resource_links_on_resource_id_and_resource_type` (`resource_id`,`resource_type`),
  KEY `index_sample_resource_links_on_sample_id` (`sample_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample_resource_links`
--

LOCK TABLES `sample_resource_links` WRITE;
/*!40000 ALTER TABLE `sample_resource_links` DISABLE KEYS */;
/*!40000 ALTER TABLE `sample_resource_links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sample_types`
--

DROP TABLE IF EXISTS `sample_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sample_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `description` text,
  `uploaded_template` tinyint(1) DEFAULT '0',
  `contributor_id` int(11) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sample_types`
--

LOCK TABLES `sample_types` WRITE;
/*!40000 ALTER TABLE `sample_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `sample_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `samples`
--

DROP TABLE IF EXISTS `samples`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `samples` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `sample_type_id` int(11) DEFAULT NULL,
  `json_metadata` text,
  `uuid` varchar(255) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `originating_data_file_id` int(11) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `samples`
--

LOCK TABLES `samples` WRITE;
/*!40000 ALTER TABLE `samples` DISABLE KEYS */;
/*!40000 ALTER TABLE `samples` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `saved_searches`
--

DROP TABLE IF EXISTS `saved_searches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `saved_searches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `search_query` text,
  `search_type` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `include_external_search` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `saved_searches`
--

LOCK TABLES `saved_searches` WRITE;
/*!40000 ALTER TABLE `saved_searches` DISABLE KEYS */;
/*!40000 ALTER TABLE `saved_searches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scales`
--

DROP TABLE IF EXISTS `scales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `key` varchar(255) DEFAULT NULL,
  `pos` int(11) DEFAULT '1',
  `image_name` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scales`
--

LOCK TABLES `scales` WRITE;
/*!40000 ALTER TABLE `scales` DISABLE KEYS */;
/*!40000 ALTER TABLE `scales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scalings`
--

DROP TABLE IF EXISTS `scalings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scalings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `scale_id` int(11) DEFAULT NULL,
  `scalable_id` int(11) DEFAULT NULL,
  `person_id` int(11) DEFAULT NULL,
  `scalable_type` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scalings`
--

LOCK TABLES `scalings` WRITE;
/*!40000 ALTER TABLE `scalings` DISABLE KEYS */;
/*!40000 ALTER TABLE `scalings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schema_migrations`
--

LOCK TABLES `schema_migrations` WRITE;
/*!40000 ALTER TABLE `schema_migrations` DISABLE KEYS */;
INSERT INTO `schema_migrations` VALUES ('20110516073535'),('20110517123801'),('20110518114659'),('20110805142241'),('20110901081405'),('20110906133647'),('20110919131359'),('20110920130259'),('20110925105559'),('20111005073850'),('20111005074035'),('20111005074321'),('20111010113052'),('20111010121606'),('20111014093022'),('20111230132855'),('20111230141102'),('20120102135414'),('20120111132446'),('20120112110613'),('20120201145756'),('20120216111032'),('20120220135318'),('20120220153537'),('20120227103248'),('20120312131223'),('20120312133628'),('20120313110655'),('20120313111734'),('20120320121043'),('20120425081000'),('20120606091324'),('20120717120848'),('20120718174723'),('20120726155438'),('20120803084456'),('20120822134905'),('20120903104214'),('20120904130127'),('20120904133049'),('20120926153416'),('20120927154238'),('20120928095812'),('20121004160305'),('20121018083626'),('20121018132006'),('20121019092421'),('20121122102133'),('20121122113420'),('20130124171456'),('20130125134747'),('20130125164227'),('20130128164658'),('20130213141244'),('20130213142802'),('20130213142855'),('20130213143041'),('20130213143740'),('20130213143924'),('20130213143959'),('20130213144333'),('20130213144443'),('20130213145755'),('20130214112850'),('20130214114348'),('20130214115312'),('20130214135530'),('20130326141320'),('20130510095830'),('20130626105656'),('20130627093804'),('20130809144222'),('20130813102022'),('20130910122251'),('20130924091747'),('20131008125317'),('20131009074223'),('20131009074806'),('20131009111037'),('20131009112843'),('20131009131404'),('20131010074148'),('20131010075304'),('20131010080439'),('20131010081432'),('20131015082641'),('20131015082642'),('20131015082643'),('20131015082645'),('20131015082646'),('20131015082647'),('20131015082648'),('20131015082649'),('20131015082650'),('20131015082651'),('20131015082652'),('20131015082653'),('20131015082654'),('20131015082655'),('20131015082656'),('20131015082657'),('20131015124110'),('20131015144138'),('20131016101128'),('20131017123546'),('20131021114102'),('20131021131913'),('20131021141007'),('20131022095336'),('20131022100420'),('20131022100520'),('20131022125156'),('20131022125157'),('20131022125846'),('20131024130645'),('20131028120543'),('20131028132754'),('20131028132930'),('20131120102952'),('20131120102953'),('20131120102954'),('20131120102955'),('20131121115947'),('20131126101335'),('20131127130347'),('20131127134016'),('20131127135908'),('20131127140231'),('20131128162257'),('20131128162518'),('20131128173209'),('20131202163217'),('20131206153614'),('20131210150859'),('20131210150904'),('20131211143517'),('20131211143518'),('20131211143519'),('20131211143520'),('20140115101849'),('20140115104313'),('20140115104607'),('20140122135530'),('20140122143728'),('20140127101552'),('20140127101602'),('20140131150157'),('20140131155853'),('20140210115148'),('20140319164904'),('20140319165730'),('20140326114330'),('20140326132324'),('20140326133055'),('20140327111037'),('20140331103515'),('20140403092453'),('20140403123503'),('20140403123551'),('20140429094203'),('20140429102909'),('20140429145610'),('20140429150534'),('20140513124340'),('20140514144438'),('20140516131826'),('20140619133724'),('20140625100641'),('20140625104050'),('20140625135500'),('20140908115546'),('20140908142454'),('20140911131032'),('20140916130030'),('20141013090204'),('20141013102857'),('20141014124733'),('20141015162033'),('20141016093319'),('20141017125035'),('20141028160723'),('20141028161450'),('20141031161125'),('20141103143919'),('20141103180407'),('20141103180504'),('20141105105548'),('20141105105640'),('20141105110711'),('20141105141228'),('20141105141425'),('20141105164405'),('20141105165558'),('20141106110811'),('20141106114058'),('20141106153545'),('20141120150356'),('20141120160953'),('20141125101549'),('20141201144047'),('20141204122730'),('20150228162650'),('20150430125628'),('20150611092045'),('20150625124744'),('20150625131437'),('20150629140310'),('20150721134955'),('20150728133757'),('20150804121500'),('20150817133103'),('20150817133253'),('20150818095633'),('20150903134052'),('20150923121841'),('20150925145748'),('20150928130911'),('20150930120551'),('20151001131852'),('20151008141054'),('20151009130408'),('20151027112319'),('20151028144957'),('20151028145013'),('20151104113035'),('20151106154128'),('20151117113026'),('20151119104941'),('20151119113254'),('20151119113554'),('20151119154010'),('20151130111940'),('20160128161633'),('20160129154301'),('20160201110138'),('20160201111736'),('20160201114822'),('20160202151214'),('20160202163607'),('20160203105204'),('20160203105328'),('20160203112519'),('20160203112531'),('20160203112614'),('20160210152956'),('20160210160818'),('20160211103607'),('20160211150242'),('20160212141028'),('20160217094908'),('20160217095229'),('20160217100536'),('20160218105235'),('20160219121836'),('20160222131559'),('20160223105040'),('20160223132539'),('20160223154009'),('20160223155557'),('20160303120458'),('20160307135036'),('20160309113850'),('20160309155638'),('20160310162232'),('20160408082534'),('20160504151342'),('20160504151626'),('20160505094646'),('20160513124317'),('20160517095615'),('20160517150444'),('20160531141452'),('20160824142312'),('20160912130902'),('20161010095349'),('20161011101739'),('20161027093957'),('20161124134422'),('20161129143629'),('20161129143735'),('20161130102656'),('20161208144901'),('20161212133015'),('20161212134619'),('20161213105545'),('20170117145632'),('20170124172923'),('20170215145129'),('20170301154749'),('20170309144237'),('20170309145516'),('20170321115012'),('20170406151110'),('20170602091314'),('20170607095453'),('20170711121424'),('20170717143912'),('20170717144002'),('20170829125634'),('20170920094317'),('20171006143805'),('20171010135127'),('20171011095056'),('20171025100714'),('20171026131121'),('20171107102053'),('20171128133429'),('20180117112653'),('20180117120616'),('20180122104144'),('20180122105511'),('20180122105804'),('20180122114153'),('20180122115427'),('20180122121232'),('20180125113031'),('20180205100124'),('20180205164153'),('20180205164203'),('20180205164213'),('20180205164611'),('20180207102508'),('20180213151824'),('20180316174049'),('20180410093814'),('20180419180203'),('20180429151412'),('20180612090556'),('20180612090557'),('20180803110015'),('20180815104210'),('20180815104230'),('20180815104231'),('20180815104232'),('20180913123624'),('20180918132758'),('20180919143203'),('20180924152253'),('20180925103340'),('20181011134514'),('20181102134542'),('20181109161058'),('20181113111833'),('20181128142428'),('20181210162148'),('20190403124116'),('20190408163210'),('20190409102235'),('20190409102407'),('20190410121245'),('20190410121821'),('20190410122522'),('20190426200617'),('20190426210303'),('20190428221140'),('20190712093046'),('20190712094906'),('20190730080909');
/*!40000 ALTER TABLE `schema_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) NOT NULL,
  `data` mediumtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=213 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
INSERT INTO `sessions` VALUES (1,'0c7aa81ac4ac905b6888cb48abed9901','BAh7B0kiEF9jc3JmX3Rva2VuBjoGRUZJIjFpcVFQL0pRdmQ4dFJkVlY5d1BP\nV0cxZVlnd1ZzM05MRFdaN3dDQ2dRMjg4PQY7AEZJIgx1c2VyX2lkBjsARmkG\n','2019-09-03 12:33:38','2019-09-03 12:39:56'),(2,'a8ec2df00af2f6d88b8a04e2871486db','BAh7BkkiCmZsYXNoBjoGRVR7B0kiDGRpc2NhcmQGOwBUWwBJIgxmbGFzaGVz\nBjsAVHsGSSIKZXJyb3IGOwBGSSIgVGhlIFByb2plY3QgZG9lcyBub3QgZXhp\nc3QhBjsAVA==\n','2019-09-03 12:33:52','2019-09-03 12:33:52'),(3,'5edf603e8e172a5f79317cf5a25a1471','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:26','2019-09-03 12:36:26'),(4,'c91751f76cb0f16d84f89f640c57e037','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:26','2019-09-03 12:36:27'),(5,'2fd79b4d1925c9cdf2dee9f34e3df715','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:27','2019-09-03 12:36:27'),(6,'798de80c79759c7876dc686c618d00b0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:27','2019-09-03 12:36:27'),(7,'8e945e558f325fc5b212764909c9ae1d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:27','2019-09-03 12:36:28'),(8,'cc77d0964d9f849eb19d45dd5a220eba','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:28','2019-09-03 12:36:28'),(9,'eafff7da3e12bed2b7c584493b7226d7','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:28','2019-09-03 12:36:28'),(10,'4d30b76d9a5f1f62cefe47d72e4011e5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:29','2019-09-03 12:36:29'),(11,'18f0457b4e37b6c4575dab56f4d9b39e','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:29','2019-09-03 12:36:29'),(12,'2ff9601ecc2d1138bbf98f4727efee56','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:36:29','2019-09-03 12:36:30'),(13,'3d6485456de7831c07ba03779c524bc6','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:39','2019-09-03 12:37:39'),(14,'7ad83e4180db496eadc37d113cd25e9e','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:39','2019-09-03 12:37:39'),(15,'9d2ae4288d17cf505ec8a77aa0994321','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:39','2019-09-03 12:37:40'),(16,'0a7febaca9d1d2dcb15eb726b95c5869','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:40','2019-09-03 12:37:40'),(17,'c935c2ccfe6f1972859d9a80a6e91a22','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:40','2019-09-03 12:37:40'),(18,'d19157a649d51f4ff50429285e205119','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:41','2019-09-03 12:37:41'),(19,'49c705ee01a18eea9b0c4ce55a723612','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:41','2019-09-03 12:37:41'),(20,'056a8d7d35edbf599b20d3349ce6ad24','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:42','2019-09-03 12:37:42'),(21,'8511bd1f3173902b751d6151be1315f5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:42','2019-09-03 12:37:42'),(22,'2f75bedf9e8cd9ff35d3706629866d5a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:43','2019-09-03 12:37:43'),(23,'d9933ffb04badd909243923229a341be','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:43','2019-09-03 12:37:43'),(24,'e373464da21c590a699abda4f4208000','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:44','2019-09-03 12:37:44'),(25,'369d73fa5048a62196718c5ce292262c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:44','2019-09-03 12:37:44'),(26,'2e3ac70b74e50ea2076397fcbda34117','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:44','2019-09-03 12:37:45'),(27,'fdc691517113de7fb9fc16387de47235','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:45','2019-09-03 12:37:45'),(28,'83a851ef39de71d592f37290b9835371','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:45','2019-09-03 12:37:45'),(29,'d0328f74cf5331c8cae816139bb8960a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:45','2019-09-03 12:37:46'),(30,'43b310206d4df4f7465a42ad8b7033cb','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:46','2019-09-03 12:37:46'),(31,'7faaf5a63b7893ba31090ed978447fd9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:46','2019-09-03 12:37:46'),(32,'075bc95cf229459ec06c76e59b9d4ec1','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:47','2019-09-03 12:37:47'),(33,'73a2e7d0585efa2944d581e473f951e1','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:47','2019-09-03 12:37:47'),(34,'15841cbde3e56062c957344fb317e1d1','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:47','2019-09-03 12:37:48'),(35,'ccd3c0601e3a7133f6e4ac8478144fbd','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:48','2019-09-03 12:37:48'),(36,'3eb0bf1768e4f798ce2559d7da18b550','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:48','2019-09-03 12:37:49'),(37,'4033e5ba9700ded9b9fcccf595fca4b7','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:49','2019-09-03 12:37:49'),(38,'1644a3ed9af204c7ac88c878efe00eb0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:49','2019-09-03 12:37:50'),(39,'c72ec2835f0c939c86fe52f8e5b9a8d9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:50','2019-09-03 12:37:50'),(40,'755310293ddf633dc060ec1cde6825d4','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:51','2019-09-03 12:37:51'),(41,'56060c8452b510594e4777c9773f1b30','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:51','2019-09-03 12:37:51'),(42,'f4f929544c7e6c5a25660af0f54f9309','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:52','2019-09-03 12:37:52'),(43,'9a2ad78a6f2bcdcd9705dce1312f65ef','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:52','2019-09-03 12:37:52'),(44,'6ec68ab156bec1c798a1560dd5cc4375','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:53','2019-09-03 12:37:53'),(45,'0dc5a2f2fbd1112533a932235e20fb2c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:53','2019-09-03 12:37:53'),(46,'42417b2f94bcc004ea7c199ff51d9194','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:53','2019-09-03 12:37:54'),(47,'cb44ad7330735896c8b9da76ed8dcfff','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:54','2019-09-03 12:37:54'),(48,'d2156faf4f7e6413bc0d621afbb2d590','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:54','2019-09-03 12:37:55'),(49,'defa47641920074534fff3fc748e32ac','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:55','2019-09-03 12:37:55'),(50,'bbf3919d2bf3566caa3b0e740887a8ad','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:55','2019-09-03 12:37:56'),(51,'b568ada72c393b95bba11ae9c7a07486','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:56','2019-09-03 12:37:56'),(52,'a7fd6ce7848adf5dd9e1f576251b416d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:56','2019-09-03 12:37:57'),(53,'74566e8156f766c2ec645bf8db8bcdb4','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:57','2019-09-03 12:37:57'),(54,'bc1fb28ed11825917254fd9dac4f3c36','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:57','2019-09-03 12:37:58'),(55,'315276e4f4deefdd73628eb52d9ce568','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:58','2019-09-03 12:37:58'),(56,'1fa6fc772f700ccff57b27165ff97121','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:58','2019-09-03 12:37:58'),(57,'3d7961a797a176f394c28d409f1506f9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:58','2019-09-03 12:37:59'),(58,'d4d14b9132ef1bb9edfec7cbe0f622f5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:37:59','2019-09-03 12:37:59'),(59,'a8c7039ee6476e227c8c5fd83a11a641','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:37:59','2019-09-03 12:37:59'),(60,'f0fd6366ff86f995f3e7963e91ac519b','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:00','2019-09-03 12:38:00'),(61,'e1852031d57bfe4fc3f178061d61649f','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:00','2019-09-03 12:38:00'),(62,'a9358486be3f38244fd0a2d444d70b3c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:01','2019-09-03 12:38:01'),(63,'79e0312e21b777b60adf794b6d3621f4','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:01','2019-09-03 12:38:01'),(64,'0f948e82fde3b7edbab53ee8b2a41f8b','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:01','2019-09-03 12:38:02'),(65,'6675484f0e81ee55cde9b7356a133ea7','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:02','2019-09-03 12:38:02'),(66,'cbaacd1a783b2eef5da1b1bd763efae0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:02','2019-09-03 12:38:03'),(67,'a4ec8ad2f86924d1f59af21fd3b473bb','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:03','2019-09-03 12:38:03'),(68,'7495ded54476c9b45b37e634912f70ec','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:04','2019-09-03 12:38:04'),(69,'37f2e901fba235d50cd5b5013a2ddd12','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:04','2019-09-03 12:38:04'),(70,'d296bbf90ccb645503e1854def50443e','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:05','2019-09-03 12:38:06'),(71,'95aeaed27d7c4b2f59f5fcd5d16e3c87','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:06','2019-09-03 12:38:06'),(72,'f2722dfd0300fdac8a113a6fae16016f','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:06','2019-09-03 12:38:06'),(73,'8ce225d9941441ad2fbd08c2e0f056b9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:06','2019-09-03 12:38:06'),(74,'ae82476f1a5d89567e5e0f90275dd630','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:07','2019-09-03 12:38:07'),(75,'942166f4ba0c281c9c2b7504481ddb5e','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:07','2019-09-03 12:38:07'),(76,'700a7a234c991c9788918188d0a643ea','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:08','2019-09-03 12:38:08'),(77,'3473eb93bf874ba2c00047f2acabbe79','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:08','2019-09-03 12:38:08'),(78,'59f8d50ef0dc71d5eefad1171cf889a2','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:08','2019-09-03 12:38:09'),(79,'7294d05a3bdb99014d2c0a041c570961','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:09','2019-09-03 12:38:09'),(80,'9fa7aaf0f8164d33d149d5739ee17d00','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:09','2019-09-03 12:38:10'),(81,'3ae65a1aa47df3cb0eeac3f24b929bc3','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:10','2019-09-03 12:38:10'),(82,'3463a3739f3586e5e5574d12d19378dc','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:10','2019-09-03 12:38:11'),(83,'98d87111ba4eb7a89490b61e4e60597b','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:11','2019-09-03 12:38:11'),(84,'bee3e6f10d8945e967fc35b2cd6c95f9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:11','2019-09-03 12:38:12'),(85,'e5fbdd09c3a200c90ee78ba7fd12b930','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:12','2019-09-03 12:38:12'),(86,'26739a8308ca92178a59659ed1e24a12','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:12','2019-09-03 12:38:13'),(87,'c9bf0aac753160d703fde083877eed27','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:13','2019-09-03 12:38:13'),(88,'236c6f60570e42e26ee779a7117f7092','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:13','2019-09-03 12:38:13'),(89,'1f1f287a4db19a2d44cfc6d44f1e7232','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:13','2019-09-03 12:38:14'),(90,'1230b5a2a6fcf543894f855730463121','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:14','2019-09-03 12:38:14'),(91,'49fd0cdf0ad6e2ecf97ab47c188febe9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:14','2019-09-03 12:38:14'),(92,'4623d45778e4d897f7ad2b23bc0e4f3f','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:15','2019-09-03 12:38:15'),(93,'ef30797110f9601a5cd1c4447e782fd3','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:15','2019-09-03 12:38:15'),(94,'24f1000cdf5535d9e845b0eac97cf505','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:16','2019-09-03 12:38:16'),(95,'e78cbdc2fc814f82cd803f2493dd6bca','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:16','2019-09-03 12:38:16'),(96,'4667f70969528067c6edbe32fb0b1c3c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:17','2019-09-03 12:38:17'),(97,'d4011cbe7b7790762d3d630ee03eb34a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:17','2019-09-03 12:38:17'),(98,'5b335a88c743f8546f9df5e0aab13b1a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:18','2019-09-03 12:38:18'),(99,'481cb520a01c4c7cb63ba843181141c9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:18','2019-09-03 12:38:19'),(100,'950c69917c557b75d0866be4b3107865','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:19','2019-09-03 12:38:19'),(101,'5ae415394590eda44dcdf26b4341c5eb','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:20','2019-09-03 12:38:20'),(102,'171c55f3cc8b748c78bc3f87b927a8c3','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:20','2019-09-03 12:38:21'),(103,'08ebdfbf75a11eb5d997538f15844b0a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:21','2019-09-03 12:38:21'),(104,'80998a860567c703699c173b1c8318b6','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:22','2019-09-03 12:38:22'),(105,'085be03b198e25d2cffe3484f4401215','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:22','2019-09-03 12:38:22'),(106,'9b46383a256c3f53ca2e78c56b9b4c6d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:23','2019-09-03 12:38:23'),(107,'ebfe52c1efb9b6efcfb30b52d55775a9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:23','2019-09-03 12:38:24'),(108,'106ad07fb98dac7b12fcfa61ff24cc58','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:24','2019-09-03 12:38:25'),(109,'280b683c2b164b2eab85d7e31e01da31','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:25','2019-09-03 12:38:25'),(110,'f99d77ee535c4124a36fb96f01673485','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:26','2019-09-03 12:38:26'),(111,'2ee99e58d7dd3fdb6c2d4559658ecae3','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:26','2019-09-03 12:38:27'),(112,'6a05720c6c3bf1ab668127f1e8326ee4','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:27','2019-09-03 12:38:28'),(113,'49a8a36cb0e75c08617b9dea06fd015e','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:28','2019-09-03 12:38:29'),(114,'f06f65509450f5df9470bae341b9a4ea','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:29','2019-09-03 12:38:30'),(115,'c074e573263c80351ac304c017258c8c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:30','2019-09-03 12:38:30'),(116,'ceeed8005906a07d6b647c4ffb2d7897','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:31','2019-09-03 12:38:32'),(117,'2ad8f47845f56f882d6238d50d929941','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:32','2019-09-03 12:38:32'),(118,'fdb101531f2e66e53118210136682b5a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:33','2019-09-03 12:38:34'),(119,'389cb923e69f02189fcd42079084a21d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:34','2019-09-03 12:38:34'),(120,'3536266d4e492a42467d23b6e0d6a22b','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:35','2019-09-03 12:38:36'),(121,'15815bf9d6fa659127a6fc828642cf06','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:36','2019-09-03 12:38:36'),(122,'8e26b5d7c5a663fc50460de3ebd053f6','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:36','2019-09-03 12:38:36'),(123,'8a669f64564de99a48cc3bca553284a3','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:36','2019-09-03 12:38:37'),(124,'e7b1b81e2a2b9b6ad4ec3a3203787ade','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:37','2019-09-03 12:38:37'),(125,'151a177b9b437bef05f048cbcca47f7c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:37','2019-09-03 12:38:37'),(126,'d71664d1d5790154babe14de3268f946','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:38','2019-09-03 12:38:38'),(127,'bf818321d902de2eb77a20532d1e37d5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:38','2019-09-03 12:38:38'),(128,'660f06ed0c9e2d75f3d8b71492f851dc','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:39','2019-09-03 12:38:39'),(129,'2f492952e056d83fce1aef9c13656fa2','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:39','2019-09-03 12:38:39'),(130,'fdc92b618440e6750e6ec56258847556','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:40','2019-09-03 12:38:40'),(131,'9a9719e31ee211c206c5afa20f2ce0ab','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:40','2019-09-03 12:38:40'),(132,'fdf6ae7b00290618057f0b99e2848446','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:41','2019-09-03 12:38:41'),(133,'e4b851a4786896441832d966a633e725','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:41','2019-09-03 12:38:42'),(134,'da6aad0c162a43aa6a76e79d4b5b3ca8','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:42','2019-09-03 12:38:42'),(135,'2763fbac3e7c81ae6263968c85e5de79','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:43','2019-09-03 12:38:43'),(136,'9e18e988399104d6fa083c31f261ed3a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:43','2019-09-03 12:38:44'),(137,'9901d05d600ac025f04da07c21e6a5cb','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:44','2019-09-03 12:38:44'),(138,'3bc5ed405587fb401ea3c9164291ecc5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:45','2019-09-03 12:38:45'),(139,'490f7a5d26c4cc6099c8aa9e23b3765a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:45','2019-09-03 12:38:45'),(140,'bda40ab534687e410d889a40fd564732','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:46','2019-09-03 12:38:46'),(141,'e3edb98cc0ff2cfa04f658cf5dc454e6','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:47','2019-09-03 12:38:47'),(142,'f0cfded401b80eaee531f0dc61f88ec5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:47','2019-09-03 12:38:47'),(143,'003dc21c3016e51d703746b708a7e021','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:47','2019-09-03 12:38:47'),(144,'704cf25a656ed162f69f92b6eb1478e0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:48','2019-09-03 12:38:48'),(145,'2fe1c106b9f8bb5eb6c5658233270b16','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:48','2019-09-03 12:38:48'),(146,'fd31470cbb05fdbae391d7b80a6c6407','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:48','2019-09-03 12:38:49'),(147,'8ae743684af922d82fda199c6f6d1d7d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:49','2019-09-03 12:38:49'),(148,'fca6528fa7b39f7c6c61eac3be6bc1b1','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:49','2019-09-03 12:38:50'),(149,'9a5cbef951893580050442c38188eb3e','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:50','2019-09-03 12:38:50'),(150,'f71860e0ead5a7021defe1ca968fb577','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:50','2019-09-03 12:38:51'),(151,'5a7ecc4763b1f496b6e052155d2e30e9','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:51','2019-09-03 12:38:51'),(152,'64623d00531a079c7255ea3e512a8cc8','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:51','2019-09-03 12:38:52'),(153,'ce041eecdb7655f44efbbde2a81d6f9d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:52','2019-09-03 12:38:52'),(154,'16a71535ed19b916f86cb51a5078e543','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:53','2019-09-03 12:38:53'),(155,'463288fa9cff6bf08e2988bcdc3c1e7a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:53','2019-09-03 12:38:53'),(156,'66b4860486ae0e39955071bbfe387268','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:54','2019-09-03 12:38:54'),(157,'4af62a51b5014b65c443e6507b6d61eb','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:54','2019-09-03 12:38:55'),(158,'8479d26108d108774f1133f93cfb0e9b','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:55','2019-09-03 12:38:56'),(159,'46053fb8ad1c82cf652729bd8c8fe2e0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:56','2019-09-03 12:38:56'),(160,'a4ed10a876b98d91bcc2c981e735ab53','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:56','2019-09-03 12:38:57'),(161,'58cac503ebe6ceb8542e175bfc22b621','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:57','2019-09-03 12:38:57'),(162,'9b358d8a8e332f247d8b58dbd93a0c23','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:58','2019-09-03 12:38:58'),(163,'21181735b435e61688aefbefb405cdb8','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:58','2019-09-03 12:38:59'),(164,'b7ad4dbe39fcb88705a9330025c1b7a0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:38:59','2019-09-03 12:38:59'),(165,'2c111ee2b8a559115330c58e0d2f16e7','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:38:59','2019-09-03 12:38:59'),(166,'771c28f149cf8ce7a19b41992b49f08c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:00','2019-09-03 12:39:00'),(167,'2a32bd2c1c074849cf8ceac1d67362ca','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:00','2019-09-03 12:39:00'),(168,'0d81ef6f1d3f0c07755bbac0cfda3c63','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:00','2019-09-03 12:39:01'),(169,'94285ab3a21fc8f848546c256b868a27','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:01','2019-09-03 12:39:01'),(170,'052b1d604619ae28df20a0f4444bdfe6','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:01','2019-09-03 12:39:02'),(171,'359894c9e4de7bb8c8d4a80bcc02ac93','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:02','2019-09-03 12:39:02'),(172,'016bb242243b8920574ff22775307108','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:02','2019-09-03 12:39:03'),(173,'4ce538058454ba1a4714bab654027bad','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:03','2019-09-03 12:39:03'),(174,'02942f462fa0914b7e33dc8d2479c12c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:03','2019-09-03 12:39:04'),(175,'ea8b6ab1d29dbdcd477e321cb42b1431','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:04','2019-09-03 12:39:04'),(176,'0948a262889ddc9ab94338c12e5565c7','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:05','2019-09-03 12:39:05'),(177,'63444168dd62ac114de0e06dde60c15c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:05','2019-09-03 12:39:05'),(178,'488fac444885cf92dfa1bc5ec6a44022','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:06','2019-09-03 12:39:06'),(179,'5c5126442c546ce847bdf5ec7c138af0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:07','2019-09-03 12:39:07'),(180,'b55527360a5d3981c448595aacabd6a5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:07','2019-09-03 12:39:08'),(181,'1944aa0236574d63fb54ea4bcffd8285','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:08','2019-09-03 12:39:08'),(182,'02503ba7cb29fa8aa4989cd233c0de31','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:08','2019-09-03 12:39:09'),(183,'cddaf0f9500a539c6a93fef5092be3f7','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:09','2019-09-03 12:39:09'),(184,'0ff1d0f85fe2f6cab0e6aee58154bde5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:10','2019-09-03 12:39:10'),(185,'dafabca9f1d73e5c713ef5535540b06d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:11','2019-09-03 12:39:11'),(186,'34883a694e4cd0ccbd86d0efc2da565e','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:11','2019-09-03 12:39:11'),(187,'de422b8a05d1f012bbfd71395c0baf1c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:11','2019-09-03 12:39:11'),(188,'70416ff0990bfed55feb38514fc0d2e3','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:12','2019-09-03 12:39:12'),(189,'1c279f19c99376675b8554de35e66f33','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:12','2019-09-03 12:39:12'),(190,'37a5bca1d9ec3dd1fa0db10e0c9e4832','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:13','2019-09-03 12:39:13'),(191,'53c8fda530620d443f704f97f866e101','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:13','2019-09-03 12:39:13'),(192,'c136bd94fc00623a7dd0bf10dc4e3609','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:14','2019-09-03 12:39:14'),(193,'e8e1e579407d59d06993f5989c1885fd','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:14','2019-09-03 12:39:14'),(194,'883b930c9e7ecd95dcd8f3e4eb9f9817','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:15','2019-09-03 12:39:15'),(195,'b192e3f9e64287808348907896a5b45a','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:15','2019-09-03 12:39:15'),(196,'d6c4599e8909f2c0f7e56629ec6ceefd','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:16','2019-09-03 12:39:16'),(197,'82b80c03d7c7a4cd4b45b0decd58fd5d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:16','2019-09-03 12:39:16'),(198,'248456b26cb2433a3422e949c71832dc','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:17','2019-09-03 12:39:17'),(199,'1e71915552191cd8ceb9226e19a31d24','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:17','2019-09-03 12:39:17'),(200,'598ee6f1e2e9576e687fae63e0f4e53c','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:18','2019-09-03 12:39:18'),(201,'d5e62abe9c6d2e1e68951323074546da','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:18','2019-09-03 12:39:19'),(202,'a7e0873572ffa46faad5c3150a89c8e4','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:19','2019-09-03 12:39:20'),(203,'ad103c6dc8c426e7b6f3692774c85246','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:20','2019-09-03 12:39:20'),(204,'0099c37f0f26fc6d67de539a369e6891','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:20','2019-09-03 12:39:21'),(205,'1291e2b1136a55cad5454cda5ad450b5','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:21','2019-09-03 12:39:21'),(206,'89bac0374ea2543c77d76b36ba071fa0','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:22','2019-09-03 12:39:22'),(207,'9391541f4b8b8bff8844c33bc99aea4d','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:23','2019-09-03 12:39:23'),(208,'cf9f3148eb74723c6109f64ff48c148f','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:23','2019-09-03 12:39:24'),(209,'67c1638291c21937d9068d63f96b6e31','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiVQZXJzb24g\nd2FzIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgY7AFQ=\n','2019-09-03 12:39:24','2019-09-03 12:39:24'),(210,'d1f075abee22b5f02f4619fa832e8089','BAh7B0kiDHVzZXJfaWQGOgZFRmkGSSIKZmxhc2gGOwBUewdJIgxkaXNjYXJk\nBjsAVFsASSIMZmxhc2hlcwY7AFR7BkkiC25vdGljZQY7AEZJIiZQcm9qZWN0\nIHdhcyBzdWNjZXNzZnVsbHkgdXBkYXRlZC4GOwBU\n','2019-09-03 12:39:25','2019-09-03 12:39:26'),(212,'1f4e0662a9a92ad1b476f66a550b98e1','BAh7B0kiEF9jc3JmX3Rva2VuBjoGRUZJIjE4eGNqOXRtd3BPenllSkZpTXNH\nSlVwWkFza2pybnk2eGpKMW53UHRJM3dRPQY7AEZJIgx1c2VyX2lkBjsARmkG\n','2020-01-12 11:18:32','2020-01-12 11:20:38');
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `settings`
--

DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `var` varchar(255) NOT NULL,
  `value` text,
  `target_id` int(11) DEFAULT NULL,
  `target_type` varchar(30) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `encrypted_value` text,
  `encrypted_value_iv` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_settings_on_target_type_and_target_id_and_var` (`target_type`,`target_id`,`var`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `settings`
--

LOCK TABLES `settings` WRITE;
/*!40000 ALTER TABLE `settings` DISABLE KEYS */;
INSERT INTO `settings` VALUES (1,'css_prepended','--- \'\'\n',NULL,NULL,'2019-09-03 12:33:10','2019-09-03 12:33:10',NULL,NULL),(2,'css_appended','--- \'\'\n',NULL,NULL,'2019-09-03 12:33:10','2019-09-03 12:33:10',NULL,NULL),(3,'main_layout','--- application\n',NULL,NULL,'2019-09-03 12:33:10','2019-09-03 12:33:10',NULL,NULL),(4,'site_base_host','--- http://localhost:3000\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(5,'pubmed_api_email','--- sowen@cs.man.ac.uk\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(6,'crossref_api_email','--- sowen@cs.man.ac.uk\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(7,'bioportal_api_key','--- 6b28065a-f37b-46a4-b6de-99879700a14a\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(8,'sabiork_ws_base_url','--- http://sabiork.h-its.org/sabioRestWebServices/\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(9,'recaptcha_enabled','--- false\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(10,'recaptcha_private_key','--- \'\'\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(11,'recaptcha_public_key','--- \'\'\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(12,'default_associated_projects_access_type','--- 2\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(13,'default_all_visitors_access_type','--- 0\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(14,'max_all_visitors_access_type','--- 2\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(15,'permissions_popup','--- 0\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(16,'auth_lookup_update_batch_size','--- 10\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(17,'allow_private_address_access','--- false\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(18,'cache_remote_files','--- true\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(19,'max_cachable_size','--- 20971520\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(20,'hard_max_cachable_size','--- 104857600\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(21,'hide_details_enabled','--- false\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(22,'registration_disabled','--- false\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(23,'registration_disabled_description','--- Registration is not available, please contact your administrator\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(24,'activation_required_enabled','--- false\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(25,'orcid_required','--- false\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL),(26,'default_license','--- CC-BY-4.0\n',NULL,NULL,'2020-01-12 11:20:37','2020-01-12 11:20:37',NULL,NULL);
/*!40000 ALTER TABLE `settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `site_announcement_categories`
--

DROP TABLE IF EXISTS `site_announcement_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `site_announcement_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `icon_key` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `site_announcement_categories`
--

LOCK TABLES `site_announcement_categories` WRITE;
/*!40000 ALTER TABLE `site_announcement_categories` DISABLE KEYS */;
/*!40000 ALTER TABLE `site_announcement_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `site_announcements`
--

DROP TABLE IF EXISTS `site_announcements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `site_announcements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `announcer_id` int(11) DEFAULT NULL,
  `announcer_type` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `body` text,
  `site_announcement_category_id` int(11) DEFAULT NULL,
  `is_headline` tinyint(1) DEFAULT '0',
  `expires_at` datetime DEFAULT NULL,
  `show_in_feed` tinyint(1) DEFAULT '1',
  `email_notification` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `site_announcements`
--

LOCK TABLES `site_announcements` WRITE;
/*!40000 ALTER TABLE `site_announcements` DISABLE KEYS */;
/*!40000 ALTER TABLE `site_announcements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `snapshots`
--

DROP TABLE IF EXISTS `snapshots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `snapshots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `resource_type` varchar(255) DEFAULT NULL,
  `resource_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `snapshot_number` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `zenodo_deposition_id` int(11) DEFAULT NULL,
  `zenodo_record_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `snapshots`
--

LOCK TABLES `snapshots` WRITE;
/*!40000 ALTER TABLE `snapshots` DISABLE KEYS */;
/*!40000 ALTER TABLE `snapshots` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sop_auth_lookup`
--

DROP TABLE IF EXISTS `sop_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sop_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_sop_auth_lookup_on_user_id_and_asset_id_and_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_sop_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sop_auth_lookup`
--

LOCK TABLES `sop_auth_lookup` WRITE;
/*!40000 ALTER TABLE `sop_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `sop_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sop_versions`
--

DROP TABLE IF EXISTS `sop_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sop_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sop_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `revision_comments` text,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sop_versions_on_contributor` (`contributor_id`),
  KEY `index_sop_versions_on_sop_id` (`sop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sop_versions`
--

LOCK TABLES `sop_versions` WRITE;
/*!40000 ALTER TABLE `sop_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sop_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sops`
--

DROP TABLE IF EXISTS `sops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `version` int(11) DEFAULT '1',
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sops_on_contributor` (`contributor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sops`
--

LOCK TABLES `sops` WRITE;
/*!40000 ALTER TABLE `sops` DISABLE KEYS */;
/*!40000 ALTER TABLE `sops` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sops_workflows`
--

DROP TABLE IF EXISTS `sops_workflows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sops_workflows` (
  `workflow_id` int(11) NOT NULL,
  `sop_id` int(11) NOT NULL,
  KEY `index_sops_workflows_on_sop_id` (`sop_id`),
  KEY `index_sops_workflows_on_workflow_id` (`workflow_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sops_workflows`
--

LOCK TABLES `sops_workflows` WRITE;
/*!40000 ALTER TABLE `sops_workflows` DISABLE KEYS */;
/*!40000 ALTER TABLE `sops_workflows` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `special_auth_codes`
--

DROP TABLE IF EXISTS `special_auth_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `special_auth_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) DEFAULT NULL,
  `expiration_date` date DEFAULT NULL,
  `asset_type` varchar(255) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `special_auth_codes`
--

LOCK TABLES `special_auth_codes` WRITE;
/*!40000 ALTER TABLE `special_auth_codes` DISABLE KEYS */;
/*!40000 ALTER TABLE `special_auth_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `strain_auth_lookup`
--

DROP TABLE IF EXISTS `strain_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `strain_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_strain_user_id_asset_id_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_strain_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `strain_auth_lookup`
--

LOCK TABLES `strain_auth_lookup` WRITE;
/*!40000 ALTER TABLE `strain_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `strain_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `strain_descendants`
--

DROP TABLE IF EXISTS `strain_descendants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `strain_descendants` (
  `ancestor_id` int(11) DEFAULT NULL,
  `descendant_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `strain_descendants`
--

LOCK TABLES `strain_descendants` WRITE;
/*!40000 ALTER TABLE `strain_descendants` DISABLE KEYS */;
/*!40000 ALTER TABLE `strain_descendants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `strains`
--

DROP TABLE IF EXISTS `strains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `strains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `organism_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `synonym` varchar(255) DEFAULT NULL,
  `comment` text,
  `provider_id` varchar(255) DEFAULT NULL,
  `provider_name` varchar(255) DEFAULT NULL,
  `is_dummy` tinyint(1) DEFAULT '0',
  `contributor_id` int(11) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `first_letter` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `strains`
--

LOCK TABLES `strains` WRITE;
/*!40000 ALTER TABLE `strains` DISABLE KEYS */;
/*!40000 ALTER TABLE `strains` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `studied_factor_links`
--

DROP TABLE IF EXISTS `studied_factor_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `studied_factor_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `substance_type` varchar(255) DEFAULT NULL,
  `substance_id` int(11) DEFAULT NULL,
  `studied_factor_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studied_factor_links`
--

LOCK TABLES `studied_factor_links` WRITE;
/*!40000 ALTER TABLE `studied_factor_links` DISABLE KEYS */;
/*!40000 ALTER TABLE `studied_factor_links` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `studied_factors`
--

DROP TABLE IF EXISTS `studied_factors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `studied_factors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `measured_item_id` int(11) DEFAULT NULL,
  `start_value` float DEFAULT NULL,
  `end_value` float DEFAULT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `time_point` float DEFAULT NULL,
  `data_file_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `standard_deviation` float DEFAULT NULL,
  `data_file_version` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_studied_factors_on_data_file_id` (`data_file_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studied_factors`
--

LOCK TABLES `studied_factors` WRITE;
/*!40000 ALTER TABLE `studied_factors` DISABLE KEYS */;
/*!40000 ALTER TABLE `studied_factors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `studies`
--

DROP TABLE IF EXISTS `studies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `studies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `investigation_id` int(11) DEFAULT NULL,
  `experimentalists` text,
  `begin_date` datetime DEFAULT NULL,
  `person_responsible_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `other_creators` text,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studies`
--

LOCK TABLES `studies` WRITE;
/*!40000 ALTER TABLE `studies` DISABLE KEYS */;
/*!40000 ALTER TABLE `studies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `study_auth_lookup`
--

DROP TABLE IF EXISTS `study_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `study_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_study_auth_lookup_on_user_id_and_asset_id_and_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_study_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `study_auth_lookup`
--

LOCK TABLES `study_auth_lookup` WRITE;
/*!40000 ALTER TABLE `study_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `study_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subscriptions`
--

DROP TABLE IF EXISTS `subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) DEFAULT NULL,
  `subscribable_id` int(11) DEFAULT NULL,
  `subscribable_type` varchar(255) DEFAULT NULL,
  `subscription_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `project_subscription_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subscriptions`
--

LOCK TABLES `subscriptions` WRITE;
/*!40000 ALTER TABLE `subscriptions` DISABLE KEYS */;
/*!40000 ALTER TABLE `subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `suggested_assay_types`
--

DROP TABLE IF EXISTS `suggested_assay_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `suggested_assay_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) DEFAULT NULL,
  `ontology_uri` varchar(255) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `parent_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `suggested_assay_types`
--

LOCK TABLES `suggested_assay_types` WRITE;
/*!40000 ALTER TABLE `suggested_assay_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `suggested_assay_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `suggested_technology_types`
--

DROP TABLE IF EXISTS `suggested_technology_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `suggested_technology_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(255) DEFAULT NULL,
  `ontology_uri` varchar(255) DEFAULT NULL,
  `contributor_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `parent_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `suggested_technology_types`
--

LOCK TABLES `suggested_technology_types` WRITE;
/*!40000 ALTER TABLE `suggested_technology_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `suggested_technology_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `synonyms`
--

DROP TABLE IF EXISTS `synonyms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `synonyms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `substance_id` int(11) DEFAULT NULL,
  `substance_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_synonyms_on_substance_id_and_substance_type` (`substance_id`,`substance_type`)
) ENGINE=InnoDB AUTO_INCREMENT=201 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `synonyms`
--

LOCK TABLES `synonyms` WRITE;
/*!40000 ALTER TABLE `synonyms` DISABLE KEYS */;
INSERT INTO `synonyms` VALUES (1,'2-Ketopropionic acid',22,'Compound','2011-08-25 16:28:54','2011-08-25 16:28:54'),(2,'2-Oxopropanoic acid',22,'Compound','2011-08-25 16:28:54','2011-08-25 16:28:54'),(3,'Pyruvic acid',22,'Compound','2011-08-25 16:28:54','2011-08-25 16:28:54'),(4,'Acetylformic acid',22,'Compound','2011-08-25 16:28:54','2011-08-25 16:28:54'),(5,'Pyroracemic acid',22,'Compound','2011-08-25 16:28:54','2011-08-25 16:28:54'),(6,'alpha-Ketopropionic acid',22,'Compound','2011-08-25 16:28:54','2011-08-25 16:28:54'),(7,'2-Oxopropanoate',22,'Compound','2011-08-25 16:28:54','2011-08-25 16:28:54'),(8,'Acetic acid',1,'Compound','2011-08-25 16:28:57','2011-08-25 16:28:57'),(9,'Ethanoic acid',1,'Compound','2011-08-25 16:28:57','2011-08-25 16:28:57'),(10,'Glacial acetic acid',1,'Compound','2011-08-25 16:28:57','2011-08-25 16:28:57'),(11,'Lactic acid',13,'Compound','2011-08-25 16:29:11','2011-08-25 16:29:11'),(12,'2-Hydroxypropionic acid',13,'Compound','2011-08-25 16:29:11','2011-08-25 16:29:11'),(13,'2-Hydroxypropanoic acid',13,'Compound','2011-08-25 16:29:11','2011-08-25 16:29:11'),(14,'Succinic acid',24,'Compound','2011-08-25 16:29:17','2011-08-25 16:29:17'),(15,'Ethylenesuccinic acid',24,'Compound','2011-08-25 16:29:17','2011-08-25 16:29:17'),(16,'Butanedionic acid',24,'Compound','2011-08-25 16:29:17','2011-08-25 16:29:17'),(17,'1,3-Bisphosphoglyceric acid',32,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(18,'1,3PG',32,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(19,'2\'-Deoxyadenosine 5\'-diphosphate',37,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(20,'2\'-Deoxyadenosine 5\'-triphosphate',38,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(21,'Deoxyadenosine 5\'-triphosphate',38,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(22,'Deoxyadenosine triphosphate',38,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(23,'2-Ketoglutarate',40,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(24,'alpha-Ketoglutarate',40,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(25,'2-Ketoglutaric acid',40,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(26,'Oxoglutaric acid',40,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(27,'alpha-Ketoglutaric acid',40,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(28,'2PG',42,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(29,'G2P',42,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(30,'D-Glycerate 2-phosphate',42,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(31,'2-Phosphoglycerate',42,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(32,'Glycerate 2-phosphate',42,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(33,'2-Phosphoglyceric acid',42,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(34,'2-Phosphoenolpyruvate',44,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(35,'PEP',44,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(36,'Phosphoenolpyruvic acid',44,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(37,'3PG',45,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(38,'3-Phosphoglyceric acid',45,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(39,'3-Phosphoglycerate',45,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(40,'D-Glycerate 3-phosphate',46,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(41,'D-Glucono-1,5-lactone 6-phosphate',52,'Compound','2011-08-25 16:29:21','2011-08-25 16:29:21'),(42,'Gluconate 6-phosphate',53,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(43,'Ethanal',54,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(44,'3-Hydroxybutan-2-one',55,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(45,'3-Hydroxy-2-butanone',55,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(46,'Dimethylketol',55,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(47,'2-Acetoin',55,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(48,'Acetyl coenzyme A',57,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(49,'Adenosine 5\'-diphosphate',58,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(50,'Adenosine diphosphate',58,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(51,'Adenosine 5\'-triphosphate',59,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(52,'Adenosine triphosphate',59,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(53,'alpha-D-Glucopyranose',60,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(54,'alpha-D-Glucopyranose 6-phosphate',61,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(55,'Adenylic acid',63,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(56,'Adenosine 5\'-phosphate',63,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(57,'5\'-AMP',63,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(58,'5\'-Adenylic acid',63,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(59,'5\'-Adenosine monophosphate',63,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(60,'Adenylate',63,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(61,'Adenosine 5\'-monophosphate',63,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(62,'beta-D-Fructofuranose 1,6-diphosphate',64,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(63,'beta-D-Fructofuranose 6-phosphate',65,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(64,'beta-D-Glucopyranose',66,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(65,'Cytidine 5\'-diphosphate',68,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(66,'Cytidine diphosphate',68,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(67,'Citric acid',70,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(68,'2-Hydroxy-1,2,3-propanetricarboxylic acid',70,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(69,'2-Hydroxytricarballylic acid',70,'Compound','2011-08-25 16:29:22','2011-08-25 16:29:22'),(70,'Cytidine triphosphate',71,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(71,'Cytidine 5\'-triphosphate',71,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(72,'Dextrose',73,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(73,'Grape sugar',73,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(74,'D-Fructose 6-phosphoric acid',76,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(75,'Neuberg ester',76,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(76,'F6P',76,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(77,'D-Galactono-8-lactone',78,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(78,'D-Galactonolactone',78,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(79,'Gluconic acid lactone',80,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(80,'Gluconic lactone',80,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(81,'G6P',81,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(82,'G3P',83,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(83,'DHAP',84,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(84,'Dihydroxyacetone phosphate',84,'Compound','2011-08-25 16:29:23','2011-08-25 16:29:23'),(85,'DPNH',87,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(86,'D-Xylono-1,5-lactone',88,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(87,'Wood sugar',89,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(88,'Ethyl alcohol',91,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(89,'Dehydrated ethanol',91,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(90,'Methylcarbinol',91,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(91,'Ethyl Alcohol',91,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(92,'Formic acid',92,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(93,'Methanoic acid',92,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(94,'Fumaric acid',94,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(95,'trans-Butenedioic acid',94,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(96,'trans-butenedioic acid',94,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(97,'Guanosine 5\'-diphosphate',95,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(98,'Guanosine diphosphate',95,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(99,'Robison ester',96,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(100,'Glycerin',98,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(101,'1,2,3-trihydroxypropane',98,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(102,'1,2,3-Propanetriol',98,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(103,'1,2,3-propanetriol',98,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(104,'1,2,3-Trihydroxypropane',98,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(105,'Guanosine 5\'-triphosphate',99,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(106,'Water',101,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(107,'Inosine diphosphate',103,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(108,'Inosine 5\'-diphosphate',103,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(109,'Inosine 5\'-triphosphate',105,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(110,'Inosine tripolyphosphate',105,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(111,'Inosine triphosphate',105,'Compound','2011-08-25 16:29:24','2011-08-25 16:29:24'),(112,'Isocitric acid',106,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(113,'1-Hydroxytricarballylic acid',106,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(114,'1-Hydroxypropane-1,2,3-tricarboxylic acid',106,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(115,'L-Malic acid',107,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(116,'L-Apple acid',107,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(117,'L-2-Hydroxybutanedioic acid',107,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(118,'Malic acid',108,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(119,'2-Hydroxybutanedioic acid',108,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(120,'TPNH',114,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(121,'Orthophosphate',116,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(122,'Pi',116,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(123,'Phosphoric acid',116,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(124,'Oxosuccinic acid',117,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(125,'keto-Oxaloacetate',117,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(126,'Oxalacetic acid',117,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(127,'Oxaloacetic acid',117,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(128,'2-oxobutanedioic acid',117,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(129,'2-Oxobutanedioic acid',117,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(130,'Succinyl coenzyme A',121,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(131,'alpha,alpha\'-Trehalose',124,'Compound','2011-08-25 16:29:25','2011-08-25 16:29:25'),(132,'Uridine 5\'-diphosphate',128,'Compound','2011-08-25 16:29:26','2011-08-25 16:29:26'),(133,'Uridine 5\'-triphosphate',129,'Compound','2011-08-25 16:29:26','2011-08-25 16:29:26'),(134,'Uridine triphosphate',129,'Compound','2011-08-25 16:29:26','2011-08-25 16:29:26'),(135,'Triphosphopyridine nucleotide',125,'Compound','2011-09-09 09:27:51','2011-09-09 09:27:51'),(136,'Nicotinamide adenine dinucleotide phosphate',125,'Compound','2011-09-09 09:27:51','2011-09-09 09:27:51'),(137,'beta-Nicotinamide adenine dinucleotide phosphate',125,'Compound','2011-09-09 09:27:51','2011-09-09 09:27:51'),(138,'TPN',125,'Compound','2011-09-09 09:27:51','2011-09-09 09:27:51'),(139,'NADP',125,'Compound','2011-09-09 09:27:51','2011-09-09 09:27:51'),(140,'TNP',125,'Compound','2011-09-09 09:27:51','2011-09-09 09:27:51'),(141,'(R)-2-Hydroxy-3-(phosphonooxy)-1-monoanhydride with phosphoric propanoic acid',29,'Compound','2011-09-12 14:07:33','2011-09-12 14:07:33'),(142,'[(2R)-2-hydroxy-3-phosphonooxy-propanoyl]oxyphosphonic acid',29,'Compound','2011-09-12 14:07:33','2011-09-12 14:07:33'),(143,'1,3-Bisphospho-D-glycerate',29,'Compound','2011-09-12 14:07:33','2011-09-12 14:07:33'),(144,'Hydrogen ion',102,'Compound','2011-09-12 14:24:00','2011-09-12 14:24:00'),(145,'(2R)-2-Hydroxy-3-(phosphonooxy)-propanal',83,'Compound','2011-11-01 13:44:42','2011-11-01 13:44:42'),(146,'(R)-2-Hydroxy-3-(phosphonooxy)-1-monoanhydride with phosphoric propanoic acid',48,'Compound','2011-11-01 13:44:42','2011-11-01 13:44:42'),(147,'[(2R)-2-hydroxy-3-phosphonooxy-propanoyl]oxyphosphonic acid',48,'Compound','2011-11-01 13:44:42','2011-11-01 13:44:42'),(148,'1,3-Bisphospho-D-glycerate',48,'Compound','2011-11-01 13:44:42','2011-11-01 13:44:42'),(149,'2-Aminopropionic acid',2,'Compound','2011-11-01 13:44:51','2011-11-01 13:44:51'),(150,'2-Aminopropanoic acid',2,'Compound','2011-11-01 13:44:51','2011-11-01 13:44:51'),(151,'2-Amino-5-guanidinovaleric acid',3,'Compound','2011-11-01 13:44:52','2011-11-01 13:44:52'),(152,'beta-Nicotinamide adenine dinucleotide phosphate',113,'Compound','2011-11-01 13:44:54','2011-11-01 13:44:54'),(153,'Triphosphopyridine nucleotide',113,'Compound','2011-11-01 13:44:54','2011-11-01 13:44:54'),(154,'Nicotinamide adenine dinucleotide phosphate',113,'Compound','2011-11-01 13:44:54','2011-11-01 13:44:54'),(155,'TPN',113,'Compound','2011-11-01 13:44:54','2011-11-01 13:44:54'),(156,'NADP',113,'Compound','2011-11-01 13:44:54','2011-11-01 13:44:54'),(157,'TNP',113,'Compound','2011-11-01 13:44:54','2011-11-01 13:44:54'),(158,'Carbon dioxide',5,'Compound','2011-11-01 13:44:55','2011-11-01 13:44:55'),(159,'2-Amino-3-mercaptopropionic acid',6,'Compound','2011-11-01 13:44:55','2011-11-01 13:44:55'),(160,'D-Fructose, 6-(dihydrogen phosphate)',76,'Compound','2011-11-01 13:44:57','2011-11-01 13:44:57'),(161,'D-Glucose, 6-(dihydrogen phosphate)',81,'Compound','2011-11-01 13:44:59','2011-11-01 13:44:59'),(162,'Diphosphopyridine nucleotide',110,'Compound','2011-11-01 13:45:00','2011-11-01 13:45:00'),(163,'Nadide',110,'Compound','2011-11-01 13:45:00','2011-11-01 13:45:00'),(164,'Nicotinamide adenine dinucleotide (oxidized)',110,'Compound','2011-11-01 13:45:00','2011-11-01 13:45:00'),(165,'Nicotinamide adenine dinucleotide',110,'Compound','2011-11-01 13:45:00','2011-11-01 13:45:00'),(166,'DPN',110,'Compound','2011-11-01 13:45:00','2011-11-01 13:45:00'),(167,'NAD',110,'Compound','2011-11-01 13:45:00','2011-11-01 13:45:00'),(168,'Nicotinamide adenine dinucleotide (reduced)',87,'Compound','2011-11-01 13:45:01','2011-11-01 13:45:01'),(169,'2-Aminoglutaric acid',9,'Compound','2011-11-01 13:45:05','2011-11-01 13:45:05'),(170,'Glutaminic acid',9,'Compound','2011-11-01 13:45:05','2011-11-01 13:45:05'),(171,'Aminoacetic acid',10,'Compound','2011-11-01 13:45:06','2011-11-01 13:45:06'),(172,'Gly',10,'Compound','2011-11-01 13:45:06','2011-11-01 13:45:06'),(173,'Hydrogen ion',100,'Compound','2011-11-01 13:45:07','2011-11-01 13:45:07'),(174,'alpha-Amino-1H-imidazole-4-propionic acid',11,'Compound','2011-11-01 13:45:08','2011-11-01 13:45:08'),(175,'(S)-Malate',107,'Compound','2011-11-01 13:45:11','2011-11-01 13:45:11'),(176,'2-Amino-4-(methylthio)butyric acid',16,'Compound','2011-11-01 13:45:11','2011-11-01 13:45:11'),(177,'Ammonia',17,'Compound','2011-11-01 13:45:16','2011-11-01 13:45:16'),(178,'Nicotinamide adenine dinucleotide',87,'Compound','2011-11-01 13:45:16','2011-11-01 13:45:16'),(179,'Oxygen',18,'Compound','2011-11-01 13:45:17','2011-11-01 13:45:17'),(180,'alpha-Amino-beta-phenylpropionic acid',20,'Compound','2011-11-01 13:45:18','2011-11-01 13:45:18'),(181,'3-Hydroxyalanine',23,'Compound','2011-11-01 13:45:21','2011-11-01 13:45:21'),(182,'2-Amino-3-hydroxypropionic acid',23,'Compound','2011-11-01 13:45:21','2011-11-01 13:45:21'),(183,'2-Amino-3-(p-hydroxyphenyl)propionic acid',26,'Compound','2011-11-01 13:45:24','2011-11-01 13:45:24'),(184,'3-(p-Hydroxyphenyl)alanine',26,'Compound','2011-11-01 13:45:24','2011-11-01 13:45:24'),(185,'2-Keto-3-deoxy-6-phosphogluconate',49,'Compound','2012-12-20 12:52:44','2012-12-20 12:52:44'),(186,'2-Dehydro-3-deoxy-D-gluconate 6-phosphate',49,'Compound','2012-12-20 12:52:44','2012-12-20 12:52:44'),(187,'2-Dehydro-3-deoxy-6-phospho-D-gluconate',49,'Compound','2012-12-20 12:52:44','2012-12-20 12:52:44'),(188,'5\'-Inosine monophosphate',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(189,'5\'-Inosinate',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(190,'Inosinic acid',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(191,'5\'-IMP',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(192,'Inosine 5\'-phosphate',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(193,'Inosine 5\'-monophosphate',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(194,'5\'-Inosinic acid',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(195,'Inosine monophosphate',104,'Compound','2012-12-20 12:52:59','2012-12-20 12:52:59'),(196,'2,5-Diaminopentanoate',19,'Compound','2012-12-20 12:53:03','2012-12-20 12:53:03'),(197,'2,5-Diaminovaleric acid',19,'Compound','2012-12-20 12:53:03','2012-12-20 12:53:03'),(198,'2,5-Diaminopentanoic acid',19,'Compound','2012-12-20 12:53:03','2012-12-20 12:53:03'),(199,'2-Oxosuccinate',117,'Compound','2012-12-20 12:53:04','2012-12-20 12:53:04'),(200,'Trehalose',124,'Compound','2012-12-20 12:53:09','2012-12-20 12:53:09');
/*!40000 ALTER TABLE `synonyms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `taggings`
--

DROP TABLE IF EXISTS `taggings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `taggings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_id` int(11) DEFAULT NULL,
  `taggable_id` int(11) DEFAULT NULL,
  `tagger_id` int(11) DEFAULT NULL,
  `tagger_type` varchar(255) DEFAULT NULL,
  `taggable_type` varchar(255) DEFAULT NULL,
  `context` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_taggings_on_tag_id` (`tag_id`),
  KEY `index_taggings_on_taggable_id_and_taggable_type_and_context` (`taggable_id`,`taggable_type`,`context`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `taggings`
--

LOCK TABLES `taggings` WRITE;
/*!40000 ALTER TABLE `taggings` DISABLE KEYS */;
/*!40000 ALTER TABLE `taggings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tags`
--

LOCK TABLES `tags` WRITE;
/*!40000 ALTER TABLE `tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `text_values`
--

DROP TABLE IF EXISTS `text_values`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `text_values` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `version` int(11) DEFAULT NULL,
  `version_creator_id` int(11) DEFAULT NULL,
  `text` mediumtext NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `text_values`
--

LOCK TABLES `text_values` WRITE;
/*!40000 ALTER TABLE `text_values` DISABLE KEYS */;
INSERT INTO `text_values` VALUES (1,NULL,NULL,'Microbiology','2019-09-03 12:32:49','2019-09-03 12:32:49'),(2,NULL,NULL,'Biochemistry','2019-09-03 12:32:50','2019-09-03 12:32:50'),(3,NULL,NULL,'Genetics','2019-09-03 12:32:50','2019-09-03 12:32:50'),(4,NULL,NULL,'Molecular Biology','2019-09-03 12:32:50','2019-09-03 12:32:50'),(5,NULL,NULL,'Bioinformatics','2019-09-03 12:32:50','2019-09-03 12:32:50'),(6,NULL,NULL,'Cheminformatics','2019-09-03 12:32:50','2019-09-03 12:32:50'),(7,NULL,NULL,'Mathematical Modelling','2019-09-03 12:32:50','2019-09-03 12:32:50'),(8,NULL,NULL,'Software Engineering','2019-09-03 12:32:50','2019-09-03 12:32:50'),(9,NULL,NULL,'Data Management','2019-09-03 12:32:50','2019-09-03 12:32:50'),(10,NULL,NULL,'Biochemistry and protein analysis','2019-09-03 12:32:50','2019-09-03 12:32:50'),(11,NULL,NULL,'Cell biology','2019-09-03 12:32:50','2019-09-03 12:32:50'),(12,NULL,NULL,'Cell and tissue culture','2019-09-03 12:32:50','2019-09-03 12:32:50'),(13,NULL,NULL,'Chemical modification','2019-09-03 12:32:50','2019-09-03 12:32:50'),(14,NULL,NULL,'Computational and theoretical biology','2019-09-03 12:32:50','2019-09-03 12:32:50'),(15,NULL,NULL,'Cytometry and fluorescent microscopy','2019-09-03 12:32:50','2019-09-03 12:32:50'),(16,NULL,NULL,'Genetic analysis','2019-09-03 12:32:50','2019-09-03 12:32:50'),(17,NULL,NULL,'Genetic modification','2019-09-03 12:32:50','2019-09-03 12:32:50'),(18,NULL,NULL,'Genomics','2019-09-03 12:32:50','2019-09-03 12:32:50'),(19,NULL,NULL,'Transcriptomics','2019-09-03 12:32:50','2019-09-03 12:32:50'),(20,NULL,NULL,'Proteomics','2019-09-03 12:32:50','2019-09-03 12:32:50'),(21,NULL,NULL,'Metabolomics','2019-09-03 12:32:50','2019-09-03 12:32:50'),(22,NULL,NULL,'Immunological techniques','2019-09-03 12:32:50','2019-09-03 12:32:50'),(23,NULL,NULL,'Isolation purification and separation','2019-09-03 12:32:50','2019-09-03 12:32:50'),(24,NULL,NULL,'Virology','2019-09-03 12:32:50','2019-09-03 12:32:50'),(25,NULL,NULL,'Model organisms','2019-09-03 12:32:50','2019-09-03 12:32:50'),(26,NULL,NULL,'Pharmacology and toxicology','2019-09-03 12:32:50','2019-09-03 12:32:50'),(27,NULL,NULL,'Spectroscopy and structural analysis','2019-09-03 12:32:50','2019-09-03 12:32:50'),(28,NULL,NULL,'Synthetic chemistry','2019-09-03 12:32:50','2019-09-03 12:32:50'),(29,NULL,NULL,'Single Cell analysis','2019-09-03 12:32:50','2019-09-03 12:32:50'),(30,NULL,NULL,'SBML','2019-09-03 12:32:50','2019-09-03 12:32:50'),(31,NULL,NULL,'ODE','2019-09-03 12:32:50','2019-09-03 12:32:50'),(32,NULL,NULL,'Partial differential equations','2019-09-03 12:32:50','2019-09-03 12:32:50'),(33,NULL,NULL,'Algebraic equations','2019-09-03 12:32:50','2019-09-03 12:32:50'),(34,NULL,NULL,'Linear equations','2019-09-03 12:32:50','2019-09-03 12:32:50'),(35,NULL,NULL,'Agent-based modelling','2019-09-03 12:32:50','2019-09-03 12:32:50'),(36,NULL,NULL,'Databases','2019-09-03 12:32:50','2019-09-03 12:32:50'),(37,NULL,NULL,'Java','2019-09-03 12:32:50','2019-09-03 12:32:50'),(38,NULL,NULL,'Perl','2019-09-03 12:32:50','2019-09-03 12:32:50'),(39,NULL,NULL,'Python','2019-09-03 12:32:50','2019-09-03 12:32:50'),(40,NULL,NULL,'Copasi','2019-09-03 12:32:50','2019-09-03 12:32:50'),(41,NULL,NULL,'JWS Online','2019-09-03 12:32:50','2019-09-03 12:32:50'),(42,NULL,NULL,'Workflows','2019-09-03 12:32:50','2019-09-03 12:32:50'),(43,NULL,NULL,'Web services','2019-09-03 12:32:50','2019-09-03 12:32:50'),(44,NULL,NULL,'Matlab','2019-09-03 12:32:50','2019-09-03 12:32:50'),(45,NULL,NULL,'Mathematica','2019-09-03 12:32:50','2019-09-03 12:32:50'),(46,NULL,NULL,'Fermentation','2019-09-03 12:32:50','2019-09-03 12:32:50'),(47,NULL,NULL,'PCR','2019-09-03 12:32:50','2019-09-03 12:32:50'),(48,NULL,NULL,'rtPCR','2019-09-03 12:32:50','2019-09-03 12:32:50'),(49,NULL,NULL,'qtPCR','2019-09-03 12:32:50','2019-09-03 12:32:50'),(50,NULL,NULL,'Microarray analysis','2019-09-03 12:32:50','2019-09-03 12:32:50'),(51,NULL,NULL,'Chip-chip','2019-09-03 12:32:50','2019-09-03 12:32:50'),(52,NULL,NULL,'R','2019-09-03 12:32:50','2019-09-03 12:32:50'),(53,NULL,NULL,'Mass spectrometry','2019-09-03 12:32:50','2019-09-03 12:32:50'),(54,NULL,NULL,'Chromatography','2019-09-03 12:32:50','2019-09-03 12:32:50'),(55,NULL,NULL,'Cell designer','2019-09-03 12:32:50','2019-09-03 12:32:50'),(56,NULL,NULL,'Cytoscape','2019-09-03 12:32:50','2019-09-03 12:32:50');
/*!40000 ALTER TABLE `text_values` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tissue_and_cell_types`
--

DROP TABLE IF EXISTS `tissue_and_cell_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tissue_and_cell_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tissue_and_cell_types`
--

LOCK TABLES `tissue_and_cell_types` WRITE;
/*!40000 ALTER TABLE `tissue_and_cell_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `tissue_and_cell_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `units`
--

DROP TABLE IF EXISTS `units`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `symbol` varchar(255) DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `factors_studied` tinyint(1) DEFAULT '1',
  `order` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1052799942 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `units`
--

LOCK TABLES `units` WRITE;
/*!40000 ALTER TABLE `units` DISABLE KEYS */;
INSERT INTO `units` VALUES (23502095,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mg/g_DW','specific concentration per gram of dry weigh biomass',0,160),(44525432,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µL','microlitre',1,30),(128569078,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','g/g_DW','specific concentration per gram of dry weigh biomass',0,150),(131849255,'micrometer','2019-09-03 12:32:54','2019-09-03 12:32:54','µm','micrometer',1,440),(149472063,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','g/L','concentration per litre of corresponding comparment',1,140),(213119659,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','CFU/g','colony forming units per gram',0,300),(246812680,'month','2019-09-03 12:32:54','2019-09-03 12:32:54','mo','time',1,370),(265110944,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','sec-1','rate',0,410),(272102031,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µg/µl','concentration - microgram per microlitre',0,260),(303251610,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','min-1','rate',0,400),(346900202,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','muMol/g_DW','specific concentration per gram of dry weigh biomass',0,170),(370706647,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','°C','Celcius',1,450),(407965186,'meter','2019-09-03 12:32:54','2019-09-03 12:32:54','m','metre',0,420),(422566778,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mol','amount of substance',1,90),(434584122,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mM','concentration per litre of corresponding comparment',1,110),(443536035,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','M','concentration per litre of corresponding comparment',1,100),(444567680,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','ng','nanogram',1,70),(458910145,'week','2019-09-03 12:32:54','2019-09-03 12:32:54','wk','time',1,360),(490137447,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µg','microgram',1,60),(491343564,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','dimensionless','dimensionless',1,500),(512992492,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','a.u.','arbitrary units',1,490),(522578845,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','g','gram',1,40),(543902373,'minute','2019-09-03 12:32:54','2019-09-03 12:32:54','min','time',1,330),(563700913,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mmol/g_DW','specific concentration per gram of dry weigh biomass',0,180),(565608506,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','%','percentage',1,480),(582320163,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µmol/L','specific concentration per litre',0,230),(623964288,'centimeter','2019-09-03 12:32:54','2019-09-03 12:32:54','cm','centimeter',1,430),(627782146,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µM','concentration per litre of corresponding comparment',1,120),(630689200,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mg','milligram',1,50),(631253395,'day','2019-09-03 12:32:54','2019-09-03 12:32:54','d','time',1,350),(641184289,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mg/ml','concentration - milligram per millilitre',0,240),(646665765,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','pM','concentration per litre of corresponding comparment',1,130),(737472028,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mmol/L','specific concentration per litre',0,220),(787278530,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mmol/L_CV','specific concentration per litre of cytoplasmic volume',0,200),(802556390,'second','2019-09-03 12:32:54','2019-09-03 12:32:54','s','time',1,320),(803707897,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','L','litre',1,10),(807276879,'hour','2019-09-03 12:32:54','2019-09-03 12:32:54','h','time',1,340),(817866611,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','CFU','colony forming units',0,290),(872939841,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','rpm','revolutions per minute',1,470),(875082334,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','CFU/ml','colony forming units per millilitre',0,310),(879196749,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','h-1','rate',0,390),(879914886,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µg/ml','concentration - microgram per milliltre',0,250),(922717355,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','bar','headspace pressure',1,460),(923869648,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µmol/(g_DW*min)','specific rate per gram of dry weigh biomass',0,210),(955952038,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','µmol/L_CV','specific concentration per litre of cytoplasmic volume',0,190),(977236310,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mL','millilitre',1,20),(998404921,'year','2019-09-03 12:32:54','2019-09-03 12:32:54','yr','time',1,380),(1010822691,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','pg','picogram',1,80),(1028274690,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','L/min','flow rate',1,270),(1052799941,NULL,'2019-09-03 12:32:54','2019-09-03 12:32:54','mL/min','flow rate',1,280);
/*!40000 ALTER TABLE `units` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(255) DEFAULT NULL,
  `crypted_password` varchar(64) DEFAULT NULL,
  `salt` varchar(40) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `remember_token` varchar(255) DEFAULT NULL,
  `remember_token_expires_at` datetime DEFAULT NULL,
  `activation_code` varchar(40) DEFAULT NULL,
  `activated_at` datetime DEFAULT NULL,
  `person_id` int(11) DEFAULT NULL,
  `reset_password_code` varchar(255) DEFAULT NULL,
  `reset_password_code_until` datetime DEFAULT NULL,
  `posts_count` int(11) DEFAULT '0',
  `last_seen_at` datetime DEFAULT NULL,
  `uuid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'huxg','2a4241ebd11be78056f0fd1ee84da9a24dec1c1120ea6eec1314be8095b5afee','d3c7c110f0623bc4aa7d9f1a65f05f448fdf18e4','2019-09-03 12:33:31','2019-09-03 12:33:33',NULL,NULL,NULL,'2019-09-03 12:33:31',1,NULL,NULL,0,NULL,'f67e0ab0-b074-0137-134b-721898481898');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_groups`
--

DROP TABLE IF EXISTS `work_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `institution_id` int(11) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_work_groups_on_project_id` (`project_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_groups`
--

LOCK TABLES `work_groups` WRITE;
/*!40000 ALTER TABLE `work_groups` DISABLE KEYS */;
INSERT INTO `work_groups` VALUES (1,NULL,1,1,'2019-09-03 12:32:52','2019-09-03 12:32:52'),(2,NULL,2,2,'2019-09-03 12:33:32','2019-09-03 12:33:32'),(3,NULL,2,3,'2019-09-03 12:36:26','2019-09-03 12:36:26'),(4,NULL,2,4,'2019-09-03 12:36:26','2019-09-03 12:36:26'),(5,NULL,2,5,'2019-09-03 12:36:27','2019-09-03 12:36:27'),(6,NULL,2,6,'2019-09-03 12:36:27','2019-09-03 12:36:27'),(7,NULL,2,7,'2019-09-03 12:36:27','2019-09-03 12:36:27'),(8,NULL,2,8,'2019-09-03 12:36:28','2019-09-03 12:36:28'),(9,NULL,2,9,'2019-09-03 12:36:28','2019-09-03 12:36:28'),(10,NULL,2,10,'2019-09-03 12:36:29','2019-09-03 12:36:29'),(11,NULL,2,11,'2019-09-03 12:36:29','2019-09-03 12:36:29'),(12,NULL,2,12,'2019-09-03 12:36:29','2019-09-03 12:36:29');
/*!40000 ALTER TABLE `work_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `workflow_auth_lookup`
--

DROP TABLE IF EXISTS `workflow_auth_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `workflow_auth_lookup` (
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
  KEY `index_w_auth_lookup_on_user_id_and_asset_id_and_can_view` (`user_id`,`asset_id`,`can_view`),
  KEY `index_w_auth_lookup_on_user_id_and_can_view` (`user_id`,`can_view`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workflow_auth_lookup`
--

LOCK TABLES `workflow_auth_lookup` WRITE;
/*!40000 ALTER TABLE `workflow_auth_lookup` DISABLE KEYS */;
/*!40000 ALTER TABLE `workflow_auth_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `workflow_versions`
--

DROP TABLE IF EXISTS `workflow_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `workflow_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `workflow_id` int(11) DEFAULT NULL,
  `version` int(11) DEFAULT NULL,
  `revision_comments` text,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_workflow_versions_on_contributor` (`contributor_id`),
  KEY `index_workflow_versions_on_workflow_id` (`workflow_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workflow_versions`
--

LOCK TABLES `workflow_versions` WRITE;
/*!40000 ALTER TABLE `workflow_versions` DISABLE KEYS */;
/*!40000 ALTER TABLE `workflow_versions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `workflows`
--

DROP TABLE IF EXISTS `workflows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `workflows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `contributor_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `last_used_at` datetime DEFAULT NULL,
  `version` int(11) DEFAULT '1',
  `first_letter` varchar(1) DEFAULT NULL,
  `other_creators` text,
  `uuid` varchar(255) DEFAULT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `doi` varchar(255) DEFAULT NULL,
  `license` varchar(255) DEFAULT NULL,
  `deleted_contributor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_workflows_on_contributor` (`contributor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `workflows`
--

LOCK TABLES `workflows` WRITE;
/*!40000 ALTER TABLE `workflows` DISABLE KEYS */;
/*!40000 ALTER TABLE `workflows` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `worksheets`
--

DROP TABLE IF EXISTS `worksheets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `worksheets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `content_blob_id` int(11) DEFAULT NULL,
  `last_row` int(11) DEFAULT NULL,
  `last_column` int(11) DEFAULT NULL,
  `sheet_number` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `worksheets`
--

LOCK TABLES `worksheets` WRITE;
/*!40000 ALTER TABLE `worksheets` DISABLE KEYS */;
/*!40000 ALTER TABLE `worksheets` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-01-12 12:21:33
