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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_logs`
--

LOCK TABLES `activity_logs` WRITE;
/*!40000 ALTER TABLE `activity_logs` DISABLE KEYS */;
INSERT INTO `activity_logs` VALUES (1,'create',NULL,'User',1,'User',1,NULL,NULL,'2020-01-16 09:56:44','2020-01-16 09:56:44',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0',NULL,'sessions'),(2,'show',NULL,'Institution',2,'User',1,NULL,NULL,'2020-01-16 09:58:24','2020-01-16 09:58:24',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0','--- Heidelberg Institute for Theoretical Studies\n','institutions'),(3,'show',NULL,'Institution',2,'User',1,NULL,NULL,'2020-01-16 09:58:28','2020-01-16 09:58:28',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0','--- Heidelberg Institute for Theoretical Studies\n','institutions'),(4,'show',NULL,'Project',1,'User',1,NULL,NULL,'2020-01-16 09:59:27','2020-01-16 09:59:27',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0','--- Default Project\n','projects'),(5,'create',NULL,'Publication',1,'User',1,'Project',2,'2020-01-16 10:14:09','2020-01-16 10:14:09',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0','--- A Peer-to-Peer Based Infrastructure for Context Distribution in Mobile and Ubiquitous\n  Environments\n','publications'),(6,'update',NULL,'Publication',1,'User',1,'Project',2,'2020-01-16 10:14:31','2020-01-16 10:14:31',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0','--- A Peer-to-Peer Based Infrastructure for Context Distribution in Mobile and Ubiquitous\n  Environments\n','publications'),(7,'show',NULL,'Publication',1,'User',1,'Project',2,'2020-01-16 10:14:33','2020-01-16 10:14:33',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0','--- A Peer-to-Peer Based Infrastructure for Context Distribution in Mobile and Ubiquitous\n  Environments\n','publications'),(8,'destroy',NULL,'Publication',1,'User',1,NULL,NULL,'2020-01-16 10:14:36','2020-01-16 10:14:36',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:73.0) Gecko/20100101 Firefox/73.0','--- A Peer-to-Peer Based Infrastructure for Context Distribution in Mobile and Ubiquitous\n  Environments\n','publications'),(9,'create',NULL,'User',1,'User',1,NULL,NULL,'2020-01-17 13:19:11','2020-01-17 13:19:11',NULL,'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36',NULL,'sessions');
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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `annotation_attributes`
--

LOCK TABLES `annotation_attributes` WRITE;
/*!40000 ALTER TABLE `annotation_attributes` DISABLE KEYS */;
INSERT INTO `annotation_attributes` VALUES (1,'expertise','2020-01-16 09:50:36','2020-01-16 09:50:36','http://www.example.org/attribute#expertise'),(2,'tool','2020-01-16 09:50:36','2020-01-16 09:50:36','http://www.example.org/attribute#tool'),(3,'funding_code','2020-01-16 09:59:24','2020-01-16 09:59:24','http://www.example.org/attribute#funding_code'),(4,'tag','2020-01-16 10:14:31','2020-01-16 10:14:31','http://www.example.org/attribute#tag'),(5,'scale','2020-01-16 10:14:36','2020-01-16 10:14:36','http://www.example.org/attribute#scale'),(6,'additional_scale_info','2020-01-16 10:14:36','2020-01-16 10:14:36','http://www.example.org/attribute#additional_scale_info');
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
INSERT INTO `annotation_value_seeds` VALUES (1,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',1),(2,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',2),(3,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',3),(4,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',4),(5,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',5),(6,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',6),(7,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',7),(8,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',8),(9,1,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',9),(10,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',10),(11,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',11),(12,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',12),(13,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',13),(14,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',14),(15,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',15),(16,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',16),(17,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',17),(18,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',18),(19,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',19),(20,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',20),(21,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',21),(22,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',4),(23,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',22),(24,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',23),(25,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',1),(26,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',24),(27,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',25),(28,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',26),(29,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',27),(30,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',28),(31,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',7),(32,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',29),(33,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',30),(34,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',31),(35,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',32),(36,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',33),(37,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',34),(38,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',35),(39,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',36),(40,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',37),(41,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',38),(42,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',39),(43,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',40),(44,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',41),(45,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',42),(46,2,NULL,'2020-01-16 09:50:36','2020-01-16 09:50:36','TextValue',43),(47,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',44),(48,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',45),(49,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',46),(50,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',47),(51,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',48),(52,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',49),(53,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',50),(54,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',51),(55,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',52),(56,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',53),(57,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',54),(58,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',55),(59,2,NULL,'2020-01-16 09:50:37','2020-01-16 09:50:37','TextValue',56);
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
INSERT INTO `ar_internal_metadata` VALUES ('environment','development','2020-01-16 09:50:33','2020-01-16 09:50:33');
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
INSERT INTO `assay_classes` VALUES (1,'Experimental assay',NULL,'2020-01-16 09:50:35','2020-01-16 09:50:35','EXP'),(2,'Modelling analysis',NULL,'2020-01-16 09:50:35','2020-01-16 09:50:35','MODEL');
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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_lookup_update_queues`
--

LOCK TABLES `auth_lookup_update_queues` WRITE;
/*!40000 ALTER TABLE `auth_lookup_update_queues` DISABLE KEYS */;
INSERT INTO `auth_lookup_update_queues` VALUES (1,1,'User','2020-01-16 09:55:49','2020-01-16 09:55:49',2),(2,1,'Person','2020-01-16 09:55:50','2020-01-16 09:55:50',2),(3,1,'Publication','2020-01-16 10:14:09','2020-01-16 10:14:09',2);
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
INSERT INTO `culture_growth_types` VALUES (932425129,'chemostat','2020-01-16 09:50:34','2020-01-16 09:50:34'),(940266199,'batch','2020-01-16 09:50:34','2020-01-16 09:50:34');
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
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
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
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delayed_jobs`
--

LOCK TABLES `delayed_jobs` WRITE;
/*!40000 ALTER TABLE `delayed_jobs` DISABLE KEYS */;
INSERT INTO `delayed_jobs` VALUES (1,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Institution\nitem_id: 1\nrefresh_dependents: true\n',NULL,'2020-01-16 09:50:41',NULL,NULL,NULL,'default','2020-01-16 09:50:38','2020-01-16 09:50:38'),(2,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 1\nrefresh_dependents: true\n',NULL,'2020-01-16 09:50:41',NULL,NULL,NULL,'default','2020-01-16 09:50:38','2020-01-16 09:50:38'),(3,3,0,'--- !ruby/object:SendPeriodicEmailsJob\nfrequency: daily\n',NULL,'2020-01-16 11:00:00',NULL,NULL,NULL,'default','2020-01-16 09:50:57','2020-01-16 09:50:57'),(4,3,0,'--- !ruby/object:SendPeriodicEmailsJob\nfrequency: weekly\n',NULL,'2020-01-16 11:05:00',NULL,NULL,NULL,'default','2020-01-16 09:50:57','2020-01-16 09:50:57'),(5,3,0,'--- !ruby/object:SendPeriodicEmailsJob\nfrequency: monthly\n',NULL,'2020-01-16 11:10:00',NULL,NULL,NULL,'default','2020-01-16 09:50:57','2020-01-16 09:50:57'),(6,3,0,'--- !ruby/object:NewsFeedRefreshJob {}\n',NULL,'2020-01-16 09:51:00',NULL,NULL,NULL,'default','2020-01-16 09:50:57','2020-01-16 09:50:57'),(7,3,0,'--- !ruby/object:ContentBlobCleanerJob {}\n',NULL,'2020-01-16 09:51:00',NULL,NULL,NULL,'default','2020-01-16 09:50:57','2020-01-16 09:50:57'),(8,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 09:55:52',NULL,NULL,NULL,'authlookup','2020-01-16 09:55:49','2020-01-16 09:55:49'),(9,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 2\nrefresh_dependents: true\n',NULL,'2020-01-16 09:55:52',NULL,NULL,NULL,'default','2020-01-16 09:55:49','2020-01-16 09:55:49'),(10,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Institution\nitem_id: 2\nrefresh_dependents: true\n',NULL,'2020-01-16 09:55:53',NULL,NULL,NULL,'default','2020-01-16 09:55:50','2020-01-16 09:55:50'),(11,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 1\n',NULL,'2020-01-16 09:56:05',NULL,NULL,NULL,'default','2020-01-16 09:55:50','2020-01-16 09:55:50'),(12,2,0,'--- !ruby/object:ProjectSubscriptionJob\nproject_subscription_id: 2\n',NULL,'2020-01-16 09:56:05',NULL,NULL,NULL,'default','2020-01-16 09:55:50','2020-01-16 09:55:50'),(13,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Person\nitem_id: 1\nrefresh_dependents: true\n',NULL,'2020-01-16 09:55:53',NULL,NULL,NULL,'default','2020-01-16 09:55:50','2020-01-16 09:55:50'),(14,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 09:55:53',NULL,NULL,NULL,'authlookup','2020-01-16 09:55:50','2020-01-16 09:55:50'),(15,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 09:55:53',NULL,NULL,NULL,'authlookup','2020-01-16 09:55:50','2020-01-16 09:55:50'),(16,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 09:55:53',NULL,NULL,NULL,'authlookup','2020-01-16 09:55:50','2020-01-16 09:55:50'),(17,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 3\nrefresh_dependents: true\n',NULL,'2020-01-16 09:57:10',NULL,NULL,NULL,'default','2020-01-16 09:57:07','2020-01-16 09:57:07'),(18,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 4\nrefresh_dependents: true\n',NULL,'2020-01-16 09:57:21',NULL,NULL,NULL,'default','2020-01-16 09:57:18','2020-01-16 09:57:18'),(19,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 5\nrefresh_dependents: true\n',NULL,'2020-01-16 09:57:24',NULL,NULL,NULL,'default','2020-01-16 09:57:21','2020-01-16 09:57:21'),(20,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 6\nrefresh_dependents: true\n',NULL,'2020-01-16 10:02:01',NULL,NULL,NULL,'default','2020-01-16 10:01:58','2020-01-16 10:01:58'),(21,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 7\nrefresh_dependents: true\n',NULL,'2020-01-16 10:02:04',NULL,NULL,NULL,'default','2020-01-16 10:02:01','2020-01-16 10:02:01'),(22,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 8\nrefresh_dependents: true\n',NULL,'2020-01-16 10:02:09',NULL,NULL,NULL,'default','2020-01-16 10:02:06','2020-01-16 10:02:06'),(23,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 9\nrefresh_dependents: true\n',NULL,'2020-01-16 10:02:13',NULL,NULL,NULL,'default','2020-01-16 10:02:10','2020-01-16 10:02:10'),(24,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 10\nrefresh_dependents: true\n',NULL,'2020-01-16 10:02:25',NULL,NULL,NULL,'default','2020-01-16 10:02:22','2020-01-16 10:02:22'),(25,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 11\nrefresh_dependents: true\n',NULL,'2020-01-16 10:02:28',NULL,NULL,NULL,'default','2020-01-16 10:02:25','2020-01-16 10:02:25'),(26,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Project\nitem_id: 12\nrefresh_dependents: true\n',NULL,'2020-01-16 10:02:50',NULL,NULL,NULL,'default','2020-01-16 10:02:47','2020-01-16 10:02:47'),(27,1,0,'--- !ruby/object:SetSubscriptionsForItemJob\nsubscribable_type: Publication\nsubscribable_id: 1\nproject_ids:\n- 2\n',NULL,'2020-01-16 10:14:11',NULL,NULL,NULL,'default','2020-01-16 10:14:09','2020-01-16 10:14:09'),(28,2,0,'--- !ruby/object:RdfGenerationJob\nitem_type_name: Publication\nitem_id: 1\nrefresh_dependents: true\n',NULL,'2020-01-16 10:14:12',NULL,NULL,NULL,'default','2020-01-16 10:14:09','2020-01-16 10:14:09'),(29,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 10:14:12',NULL,NULL,NULL,'authlookup','2020-01-16 10:14:09','2020-01-16 10:14:09'),(30,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 10:14:12',NULL,NULL,NULL,'authlookup','2020-01-16 10:14:09','2020-01-16 10:14:09'),(31,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 10:14:12',NULL,NULL,NULL,'authlookup','2020-01-16 10:14:09','2020-01-16 10:14:09'),(32,0,0,'--- !ruby/object:AuthLookupUpdateJob {}\n',NULL,'2020-01-16 10:14:34',NULL,NULL,NULL,'authlookup','2020-01-16 10:14:31','2020-01-16 10:14:31');
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
INSERT INTO `disciplines` VALUES (1,'Modeller','2020-01-16 09:50:34','2020-01-16 09:50:34'),(2,'Experimentalist','2020-01-16 09:50:34','2020-01-16 09:50:34'),(3,'Bioinformatician','2020-01-16 09:50:34','2020-01-16 09:50:34');
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
  `user_id` int(11) DEFAULT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `can_view` tinyint(1) DEFAULT '0',
  `can_manage` tinyint(1) DEFAULT '0',
  `can_edit` tinyint(1) DEFAULT '0',
  `can_download` tinyint(1) DEFAULT '0',
  `can_delete` tinyint(1) DEFAULT '0',
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `group_memberships`
--

LOCK TABLES `group_memberships` WRITE;
/*!40000 ALTER TABLE `group_memberships` DISABLE KEYS */;
INSERT INTO `group_memberships` VALUES (1,1,2,'2020-01-16 09:55:50','2020-01-16 09:55:50',NULL),(2,1,1,'2020-01-16 09:55:50','2020-01-16 09:55:50',NULL);
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
INSERT INTO `institutions` VALUES (1,'Default Institution',NULL,NULL,NULL,'GB','2020-01-16 09:50:38','2020-01-16 09:50:38',NULL,'D','92dc06e0-1a73-0138-a940-2cde48001122'),(2,'Heidelberg Institute for Theoretical Studies',NULL,'Heidelberg','http://www.h-its.org/','DE','2020-01-16 09:55:50','2020-01-16 09:55:50',NULL,'H','4caef9d0-1a74-0138-a941-2cde48001122');
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
INSERT INTO `measured_items` VALUES (56985099,'acidity/PH','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(102398331,'glucose pulse','2020-01-16 09:50:35','2020-01-16 09:50:35',0),(354314687,'dry biomass concentration','2020-01-16 09:50:35','2020-01-16 09:50:35',0),(454233679,'gas flow rate','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(482839832,'concentration','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(531603560,'pressure','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(720333100,'optical density 600 nm','2020-01-16 09:50:35','2020-01-16 09:50:35',0),(736627738,'stiring rate','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(753491646,'dilution rate','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(798267462,'time','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(828043506,'buffer','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(896634288,'growth medium','2020-01-16 09:50:35','2020-01-16 09:50:35',1),(1012502157,'specific concentration','2020-01-16 09:50:35','2020-01-16 09:50:35',0),(1045310062,'temperature','2020-01-16 09:50:35','2020-01-16 09:50:35',1);
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
INSERT INTO `model_formats` VALUES (1,'BioPAX','2020-01-16 09:50:38','2020-01-16 09:50:38'),(2,'CellML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(3,'FieldML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(4,'GraphML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(5,'Image','2020-01-16 09:50:39','2020-01-16 09:50:39'),(6,'KGML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(7,'Mathematica','2020-01-16 09:50:39','2020-01-16 09:50:39'),(8,'Matlab package','2020-01-16 09:50:39','2020-01-16 09:50:39'),(9,'MFAML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(10,'PDF (Model description)','2020-01-16 09:50:39','2020-01-16 09:50:39'),(11,'R package','2020-01-16 09:50:39','2020-01-16 09:50:39'),(12,'SBML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(13,'SciLab','2020-01-16 09:50:39','2020-01-16 09:50:39'),(14,'Simile XML v3','2020-01-16 09:50:39','2020-01-16 09:50:39'),(15,'SVG','2020-01-16 09:50:39','2020-01-16 09:50:39'),(16,'SXML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(17,'Virtual Cell Markup Language (VCML)','2020-01-16 09:50:39','2020-01-16 09:50:39'),(18,'XPP','2020-01-16 09:50:39','2020-01-16 09:50:39'),(19,'Copasi','2020-01-16 09:50:39','2020-01-16 09:50:39'),(20,'MathML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(21,'XGMML','2020-01-16 09:50:39','2020-01-16 09:50:39'),(22,'SBGN-ML PD','2020-01-16 09:50:39','2020-01-16 09:50:39');
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
INSERT INTO `model_types` VALUES (1,'Ordinary differential equations (ODE)','2020-01-16 09:50:39','2020-01-16 09:50:39'),(2,'Partial differential equations (PDE)','2020-01-16 09:50:39','2020-01-16 09:50:39'),(3,'Boolean network','2020-01-16 09:50:39','2020-01-16 09:50:39'),(4,'Petri net','2020-01-16 09:50:39','2020-01-16 09:50:39'),(5,'Linear equations','2020-01-16 09:50:39','2020-01-16 09:50:39'),(6,'Algebraic equations','2020-01-16 09:50:39','2020-01-16 09:50:39'),(7,'Bayesian network','2020-01-16 09:50:39','2020-01-16 09:50:39'),(8,'Graphical model','2020-01-16 09:50:39','2020-01-16 09:50:39'),(9,'Stoichiometric model','2020-01-16 09:50:39','2020-01-16 09:50:39'),(10,'Agent based modelling','2020-01-16 09:50:39','2020-01-16 09:50:39'),(11,'Metabolic network','2020-01-16 09:50:39','2020-01-16 09:50:39');
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifiee_infos`
--

LOCK TABLES `notifiee_infos` WRITE;
/*!40000 ALTER TABLE `notifiee_infos` DISABLE KEYS */;
INSERT INTO `notifiee_infos` VALUES (1,1,'Person','4ce61e10-1a74-0138-a941-2cde48001122',1,'2020-01-16 09:55:50','2020-01-16 09:55:50');
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `people`
--

LOCK TABLES `people` WRITE;
/*!40000 ALTER TABLE `people` DISABLE KEYS */;
INSERT INTO `people` VALUES (1,'2020-01-16 09:55:50','2020-01-16 09:55:50','Xiaoming','Hu','xiaoming.hu@h-its.org','+49 (0)6221–533–218','xiaoming.hu','https://www.h-its.org/de/','Software Developer',NULL,0,'H','4cd369d0-1a74-0138-a941-2cde48001122',1,'https://orcid.org/0000-0001-9842-9718');
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
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
INSERT INTO `project_positions` VALUES (2,'Vice Coordinator','2020-01-16 09:50:35','2020-01-16 09:50:35'),(3,'Project Coordinator','2020-01-16 09:50:35','2020-01-16 09:50:35'),(4,'Student','2020-01-16 09:50:35','2020-01-16 09:50:35'),(5,'Postdoc','2020-01-16 09:50:35','2020-01-16 09:50:35'),(7,'Technician','2020-01-16 09:50:35','2020-01-16 09:50:35'),(8,'PhD Student','2020-01-16 09:50:35','2020-01-16 09:50:35');
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `project_subscriptions`
--

LOCK TABLES `project_subscriptions` WRITE;
/*!40000 ALTER TABLE `project_subscriptions` DISABLE KEYS */;
INSERT INTO `project_subscriptions` VALUES (1,1,2,'--- []\n','weekly'),(2,1,1,'--- []\n','weekly');
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
INSERT INTO `projects` VALUES (1,'Default Project',NULL,NULL,'2020-01-16 09:50:38','2020-01-16 09:55:50',NULL,NULL,NULL,'D',NULL,NULL,NULL,'92bcfb00-1a73-0138-a940-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(2,'Scientific Databases and Visualization','https://www.h-its.org/research/sdbv/',NULL,'2020-01-16 09:55:49','2020-01-16 09:55:50','Our mission is to improve data storage and the search for life science data, making storage, search, and processing simple to use for domain experts who are not computer scientists. We believe that much can be learned from running actual systems and serving their users, who can then tell us what is important for them.',NULL,NULL,'S',NULL,NULL,NULL,'4c93a540-1a74-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(3,'Molecular and Cellular Modeling','https://www.h-its.org/research/mcm/',NULL,'2020-01-16 09:57:07','2020-01-16 09:57:07','In the MCM group we are primarily interested in understanding how biomolecules interact.',NULL,NULL,'M',NULL,NULL,NULL,'7aa0de60-1a74-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(4,'Natural Language Processing','https://www.h-its.org/research/nlp/',NULL,'2020-01-16 09:57:18','2020-01-16 09:57:18','The Natural Language Processing (NLP) group develops methods, algorithms, and tools for the automatic analysis of natural language.',NULL,NULL,'N',NULL,NULL,NULL,'811d0960-1a74-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(5,'Astroinformatics','https://www.h-its.org/research/ain/',NULL,'2020-01-16 09:57:21','2020-01-16 09:57:21','The AIN group develops new methods and tools to deal with the exponentially increasing amount of data in astronomy.',NULL,NULL,'A',NULL,NULL,NULL,'83138cd0-1a74-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(6,'Computational Carbon Chemistry','https://www.h-its.org/research/ccc/',NULL,'2020-01-16 10:01:58','2020-01-16 10:01:58','The CCC group uses state-of-the-art computational chemistry to explore and exploit diverse functional organic materials.',NULL,NULL,'C',NULL,NULL,NULL,'28203ed0-1a75-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(7,'Computational Molecular Evolution','https://www.h-its.org/research/cme/',NULL,'2020-01-16 10:02:01','2020-01-16 10:02:01','The Computational Molecular Evolution (CME) group focuses on developing algorithms, computer architectures, and high-performance computing solutions for bioinformatics.',NULL,NULL,'C',NULL,NULL,NULL,'2a210060-1a75-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(8,'Molecular Biomechanics','https://www.h-its.org/research/mbm/',NULL,'2020-01-16 10:02:06','2020-01-16 10:02:06','The major interest of the Molecular Biomechanics group is to decipher how proteins have been designed to specifically respond to mechanical forces in the cellular environment or as a biomaterial.s',NULL,NULL,'M',NULL,NULL,NULL,'2d4a0d80-1a75-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(9,'Physics of Stellar Objects','https://www.h-its.org/research/pso/',NULL,'2020-01-16 10:02:10','2020-01-16 10:02:10','Our research group “Physics of Stellar Objects” seeks to understand the processes in stars and stellar explosions based on extensive numerical simulations.',NULL,NULL,'P',NULL,NULL,NULL,'2f389550-1a75-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(10,'Groups and Geometry','https://www.h-its.org/research/grg/',NULL,'2020-01-16 10:02:22','2020-01-16 10:02:22','The research group “Groups and Geometry” investigates various mathematical problems in the fields of geometry and topology, which involve the interplay between geometric spaces, such as Riemannian manifolds or metric spaces, and groups, arising for example from symmetries, acting on them.',NULL,NULL,'G',NULL,NULL,NULL,'365edf10-1a75-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(11,'Data Mining and Uncertainty Quantification','https://www.h-its.org/research/dmq/',NULL,'2020-01-16 10:02:25','2020-01-16 10:02:25','In this group we make use of stochastic mathematical models, high-performance computing, and hardware-aware computing to quantify the impact of uncertainties in large data sets and/or associated mathematical models and thus help to establish reliable insights in data mining. Currently, the fields of application are medical engineering, biology, and meteorology.',NULL,NULL,'D',NULL,NULL,NULL,'385e7980-1a75-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL),(12,'Computational Statistics','https://www.h-its.org/research/cst/',NULL,'2020-01-16 10:02:47','2020-01-16 10:02:47','The group’s current focus is on probabilistic forecasting.',NULL,NULL,'C',NULL,NULL,NULL,'4563afc0-1a75-0138-a941-2cde48001122',NULL,NULL,NULL,'CC-BY-4.0',0,NULL,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publication_types`
--

LOCK TABLES `publication_types` WRITE;
/*!40000 ALTER TABLE `publication_types` DISABLE KEYS */;
INSERT INTO `publication_types` VALUES (1,'Journal','article','2020-01-16 09:50:39','2020-01-16 09:50:39'),(2,'Book','book','2020-01-16 09:50:39','2020-01-16 09:50:39'),(3,'Booklet','booklet','2020-01-16 09:50:39','2020-01-16 09:50:39'),(4,'InBook','inbook','2020-01-16 09:50:39','2020-01-16 09:50:39'),(5,'InCollection','incollection','2020-01-16 09:50:39','2020-01-16 09:50:39'),(6,'InProceedings','inproceedings','2020-01-16 09:50:39','2020-01-16 09:50:39'),(7,'Manual','manual','2020-01-16 09:50:39','2020-01-16 09:50:39'),(8,'Misc','misc','2020-01-16 09:50:39','2020-01-16 09:50:39'),(9,'Phd Thesis','phdthesis','2020-01-16 09:50:39','2020-01-16 09:50:39'),(10,'Masters Thesis','mastersthesis','2020-01-16 09:50:39','2020-01-16 09:50:39'),(11,'Bachelors Thesis','bachelorsthesis','2020-01-16 09:50:39','2020-01-16 09:50:39'),(12,'Proceedings','proceedings','2020-01-16 09:50:39','2020-01-16 09:50:39'),(13,'Tech report','techreport','2020-01-16 09:50:39','2020-01-16 09:50:39'),(14,'Unpublished','unpublished','2020-01-16 09:50:39','2020-01-16 09:50:39');
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
  `url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_publications_on_contributor` (`contributor_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
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
INSERT INTO `recommended_model_environments` VALUES (54709254,'CPLEX Interactive Optimizer','2020-01-16 09:50:35','2020-01-16 09:50:35'),(56444055,'PathwayLab','2020-01-16 09:50:35','2020-01-16 09:50:35'),(76516951,'CellSys','2020-01-16 09:50:35','2020-01-16 09:50:35'),(104000749,'Insilico Discovery','2020-01-16 09:50:35','2020-01-16 09:50:35'),(114118389,'Gromacs','2020-01-16 09:50:35','2020-01-16 09:50:35'),(134358931,'Python Simulator for Cellular Systems (PySCeS)','2020-01-16 09:50:35','2020-01-16 09:50:35'),(275853935,'Jarnac (Systems Biology Workbench)','2020-01-16 09:50:35','2020-01-16 09:50:35'),(456178890,'Matlab','2020-01-16 09:50:35','2020-01-16 09:50:35'),(467843593,'PK-Sim','2020-01-16 09:50:35','2020-01-16 09:50:35'),(504770172,'PottersWheel','2020-01-16 09:50:35','2020-01-16 09:50:35'),(529642631,'MeVisLab','2020-01-16 09:50:35','2020-01-16 09:50:35'),(580179347,'CellDesigner (SBML ODE Solver)','2020-01-16 09:50:35','2020-01-16 09:50:35'),(729931928,'CellNetAnalyzer','2020-01-16 09:50:35','2020-01-16 09:50:35'),(757561406,'Virtual Cell','2020-01-16 09:50:35','2020-01-16 09:50:35'),(830560120,'Systems Biology Toolbox 2','2020-01-16 09:50:35','2020-01-16 09:50:35'),(857727606,'JWS Online','2020-01-16 09:50:35','2020-01-16 09:50:35'),(915852937,'Copasi','2020-01-16 09:50:35','2020-01-16 09:50:35'),(949170268,'XPP-Aut','2020-01-16 09:50:35','2020-01-16 09:50:35'),(951528555,'Mathematica','2020-01-16 09:50:35','2020-01-16 09:50:35'),(968724970,'roadrunner (Systems Biology Workbench)','2020-01-16 09:50:35','2020-01-16 09:50:35'),(999460246,'AUTO2000','2020-01-16 09:50:35','2020-01-16 09:50:35'),(1032857501,'MoBi','2020-01-16 09:50:35','2020-01-16 09:50:35');
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
INSERT INTO `relationship_types` VALUES (1,'Construction data','Data used for model testing','2020-01-16 09:50:39','2020-01-16 09:50:39','CONSTRUCTION'),(2,'Validation data','Data used for validating a model','2020-01-16 09:50:39','2020-01-16 09:50:39','VALIDATION'),(3,'Simulation results','Data resulting from running a model simulation','2020-01-16 09:50:39','2020-01-16 09:50:39','SIMULATION');
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
INSERT INTO `sample_attribute_types` VALUES (1,'Date time','DateTime','.*','2020-01-16 09:50:39','2020-01-16 09:50:39','January 1, 2015 11:30 AM',NULL,NULL),(2,'Date','Date','.*','2020-01-16 09:50:39','2020-01-16 09:50:39','January 1, 2015',NULL,NULL),(3,'Real number','Float','.*','2020-01-16 09:50:39','2020-01-16 09:50:39','3.6',NULL,NULL),(4,'Integer','Integer','.*','2020-01-16 09:50:39','2020-01-16 09:50:39','1',NULL,NULL),(5,'Web link','String','(?x-mi:(?=(?-mix:http|https):)\n        ([a-zA-Z][\\-+.a-zA-Z\\d]*):                           (?# 1: scheme)\n        (?:\n           ((?:[\\-_.!~*\'()a-zA-Z\\d;?:@&=+$,]|%[a-fA-F\\d]{2})(?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*)                    (?# 2: opaque)\n        |\n           (?:(?:\n             \\/\\/(?:\n                 (?:(?:((?:[\\-_.!~*\'()a-zA-Z\\d;:&=+$,]|%[a-fA-F\\d]{2})*)@)?        (?# 3: userinfo)\n                   (?:((?:(?:[a-zA-Z0-9\\-.]|%\\h\\h)+|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}|\\[(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})|(?:(?:[a-fA-F\\d]{1,4}:)*[a-fA-F\\d]{1,4})?::(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}))?)\\]))(?::(\\d*))?))? (?# 4: host, 5: port)\n               |\n                 ((?:[\\-_.!~*\'()a-zA-Z\\d$,;:@&=+]|%[a-fA-F\\d]{2})+)                 (?# 6: registry)\n               )\n             |\n             (?!\\/\\/))                           (?# XXX: \'\\/\\/\' is the mark for hostport)\n             (\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*(?:\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*)*)?                    (?# 7: path)\n           )(?:\\?((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                 (?# 8: query)\n        )\n        (?:\\#((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                  (?# 9: fragment)\n      )','2020-01-16 09:50:39','2020-01-16 09:50:39','http://www.example.com',NULL,'\\0'),(6,'Email address','String','(?-mix:\\A(?:[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\u00ff]+|\\x22(?:[^\\x0d\\x22\\x5c\\u0080-\\u00ff]|\\x5c[\\x00-\\x7f])*\\x22)(?:\\x2e(?:[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\u00ff]+|\\x22(?:[^\\x0d\\x22\\x5c\\u0080-\\u00ff]|\\x5c[\\x00-\\x7f])*\\x22))*\\x40(?:(?:(?:[a-zA-Z\\d](?:[-a-zA-Z\\d]*[a-zA-Z\\d])?)\\.)*(?:[a-zA-Z](?:[-a-zA-Z\\d]*[a-zA-Z\\d])?)\\.?)?[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\u00ff]+\\z)','2020-01-16 09:50:39','2020-01-16 09:50:39','someone@example.com',NULL,'mailto:\\0'),(7,'Text','Text','.*','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,NULL),(8,'String','String','.*','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,NULL),(9,'ChEBI','String','^CHEBI:\\d+$','2020-01-16 09:50:39','2020-01-16 09:50:39','CHEBI:1234',NULL,'http://identifiers.org/chebi/\\0'),(10,'ECN','String','[0-9\\.]+','2020-01-16 09:50:39','2020-01-16 09:50:39','2.7.1.121',NULL,'http://identifiers.org/brenda/\\0'),(11,'MetaNetX chemical','String','MNXM\\d+','2020-01-16 09:50:39','2020-01-16 09:50:39','MNXM01',NULL,'http://identifiers.org/metanetx.chemical/\\0'),(12,'MetaNetX reaction','String','MNXR\\d+','2020-01-16 09:50:39','2020-01-16 09:50:39','MNXR891',NULL,'http://identifiers.org/metanetx.reaction/\\0'),(13,'MetaNetX compartment','String','MNX[CD]\\d+','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,'http://identifiers.org/metanetx.compartment/\\0'),(14,'InChI','String','^InChI\\=1S?\\/[A-Za-z0-9\\.]+(\\+[0-9]+)?(\\/[cnpqbtmsih][A-Za-z0-9\\-\\+\\(\\)\\,\\/\\?\\;\\.]+)*$','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,'http://identifiers.org/inchi/\\0'),(15,'Boolean','Boolean','.*','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,NULL),(16,'SEEK Strain','SeekStrain','.*','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,NULL),(17,'SEEK Sample','SeekSample','.*','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,NULL),(18,'Controlled Vocabulary','CV','.*','2020-01-16 09:50:39','2020-01-16 09:50:39',NULL,NULL,NULL),(19,'URI','String','(?x-mi:\n        ([a-zA-Z][\\-+.a-zA-Z\\d]*):                           (?# 1: scheme)\n        (?:\n           ((?:[\\-_.!~*\'()a-zA-Z\\d;?:@&=+$,]|%[a-fA-F\\d]{2})(?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*)                    (?# 2: opaque)\n        |\n           (?:(?:\n             \\/\\/(?:\n                 (?:(?:((?:[\\-_.!~*\'()a-zA-Z\\d;:&=+$,]|%[a-fA-F\\d]{2})*)@)?        (?# 3: userinfo)\n                   (?:((?:(?:[a-zA-Z0-9\\-.]|%\\h\\h)+|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}|\\[(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})|(?:(?:[a-fA-F\\d]{1,4}:)*[a-fA-F\\d]{1,4})?::(?:(?:[a-fA-F\\d]{1,4}:)*(?:[a-fA-F\\d]{1,4}|\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}))?)\\]))(?::(\\d*))?))? (?# 4: host, 5: port)\n               |\n                 ((?:[\\-_.!~*\'()a-zA-Z\\d$,;:@&=+]|%[a-fA-F\\d]{2})+)                 (?# 6: registry)\n               )\n             |\n             (?!\\/\\/))                           (?# XXX: \'\\/\\/\' is the mark for hostport)\n             (\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*(?:\\/(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*(?:;(?:[\\-_.!~*\'()a-zA-Z\\d:@&=+$,]|%[a-fA-F\\d]{2})*)*)*)?                    (?# 7: path)\n           )(?:\\?((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                 (?# 8: query)\n        )\n        (?:\\#((?:[\\-_.!~*\'()a-zA-Z\\d;\\/?:@&=+$,\\[\\]]|%[a-fA-F\\d]{2})*))?                  (?# 9: fragment)\n      )','2020-01-16 09:50:39','2020-01-16 09:50:39','http://www.example.com/123',NULL,'\\0'),(20,'DOI','String','(DOI:)?(.*)','2020-01-16 09:50:39','2020-01-16 09:50:39','DOI:10.1109/5.771073',NULL,'https://doi.org/\\2'),(21,'NCBI ID','String','[0-9]+','2020-01-16 09:50:39','2020-01-16 09:50:39','23234',NULL,'https://identifiers.org/taxonomy/\\0');
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
INSERT INTO `sample_controlled_vocab_terms` VALUES (1,'batch',1,'2020-01-16 09:50:40','2020-01-16 09:50:40'),(2,'chemostat',1,'2020-01-16 09:50:40','2020-01-16 09:50:40'),(3,'Whole cell',2,'2020-01-16 09:50:40','2020-01-16 09:50:40'),(4,'Membrane fraction',2,'2020-01-16 09:50:40','2020-01-16 09:50:40');
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
INSERT INTO `sample_controlled_vocabs` VALUES (1,'SysMO Cell Culture Growth Type',NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','S'),(2,'SysMO Sample Organism Part',NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','S');
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
INSERT INTO `schema_migrations` VALUES ('20110516073535'),('20110517123801'),('20110518114659'),('20110805142241'),('20110901081405'),('20110906133647'),('20110919131359'),('20110920130259'),('20110925105559'),('20111005073850'),('20111005074035'),('20111005074321'),('20111010113052'),('20111010121606'),('20111014093022'),('20111230132855'),('20111230141102'),('20120102135414'),('20120111132446'),('20120112110613'),('20120201145756'),('20120216111032'),('20120220135318'),('20120220153537'),('20120227103248'),('20120312131223'),('20120312133628'),('20120313110655'),('20120313111734'),('20120320121043'),('20120425081000'),('20120606091324'),('20120717120848'),('20120718174723'),('20120726155438'),('20120803084456'),('20120822134905'),('20120903104214'),('20120904130127'),('20120904133049'),('20120926153416'),('20120927154238'),('20120928095812'),('20121004160305'),('20121018083626'),('20121018132006'),('20121019092421'),('20121122102133'),('20121122113420'),('20130124171456'),('20130125134747'),('20130125164227'),('20130128164658'),('20130213141244'),('20130213142802'),('20130213142855'),('20130213143041'),('20130213143740'),('20130213143924'),('20130213143959'),('20130213144333'),('20130213144443'),('20130213145755'),('20130214112850'),('20130214114348'),('20130214115312'),('20130214135530'),('20130326141320'),('20130510095830'),('20130626105656'),('20130627093804'),('20130809144222'),('20130813102022'),('20130910122251'),('20130924091747'),('20131008125317'),('20131009074223'),('20131009074806'),('20131009111037'),('20131009112843'),('20131009131404'),('20131010074148'),('20131010075304'),('20131010080439'),('20131010081432'),('20131015082641'),('20131015082642'),('20131015082643'),('20131015082645'),('20131015082646'),('20131015082647'),('20131015082648'),('20131015082649'),('20131015082650'),('20131015082651'),('20131015082652'),('20131015082653'),('20131015082654'),('20131015082655'),('20131015082656'),('20131015082657'),('20131015124110'),('20131015144138'),('20131016101128'),('20131017123546'),('20131021114102'),('20131021131913'),('20131021141007'),('20131022095336'),('20131022100420'),('20131022100520'),('20131022125156'),('20131022125157'),('20131022125846'),('20131024130645'),('20131028120543'),('20131028132754'),('20131028132930'),('20131120102952'),('20131120102953'),('20131120102954'),('20131120102955'),('20131121115947'),('20131126101335'),('20131127130347'),('20131127134016'),('20131127135908'),('20131127140231'),('20131128162257'),('20131128162518'),('20131128173209'),('20131202163217'),('20131206153614'),('20131210150859'),('20131210150904'),('20131211143517'),('20131211143518'),('20131211143519'),('20131211143520'),('20140115101849'),('20140115104313'),('20140115104607'),('20140122135530'),('20140122143728'),('20140127101552'),('20140127101602'),('20140131150157'),('20140131155853'),('20140210115148'),('20140319164904'),('20140319165730'),('20140326114330'),('20140326132324'),('20140326133055'),('20140327111037'),('20140331103515'),('20140403092453'),('20140403123503'),('20140403123551'),('20140429094203'),('20140429102909'),('20140429145610'),('20140429150534'),('20140513124340'),('20140514144438'),('20140516131826'),('20140619133724'),('20140625100641'),('20140625104050'),('20140625135500'),('20140908115546'),('20140908142454'),('20140911131032'),('20140916130030'),('20141013090204'),('20141013102857'),('20141014124733'),('20141015162033'),('20141016093319'),('20141017125035'),('20141028160723'),('20141028161450'),('20141031161125'),('20141103143919'),('20141103180407'),('20141103180504'),('20141105105548'),('20141105105640'),('20141105110711'),('20141105141228'),('20141105141425'),('20141105164405'),('20141105165558'),('20141106110811'),('20141106114058'),('20141106153545'),('20141120150356'),('20141120160953'),('20141125101549'),('20141201144047'),('20141204122730'),('20150228162650'),('20150430125628'),('20150611092045'),('20150625124744'),('20150625131437'),('20150629140310'),('20150721134955'),('20150728133757'),('20150804121500'),('20150817133103'),('20150817133253'),('20150818095633'),('20150903134052'),('20150923121841'),('20150925145748'),('20150928130911'),('20150930120551'),('20151001131852'),('20151008141054'),('20151009130408'),('20151027112319'),('20151028144957'),('20151028145013'),('20151104113035'),('20151106154128'),('20151117113026'),('20151119104941'),('20151119113254'),('20151119113554'),('20151119154010'),('20151130111940'),('20160128161633'),('20160129154301'),('20160201110138'),('20160201111736'),('20160201114822'),('20160202151214'),('20160202163607'),('20160203105204'),('20160203105328'),('20160203112519'),('20160203112531'),('20160203112614'),('20160210152956'),('20160210160818'),('20160211103607'),('20160211150242'),('20160212141028'),('20160217094908'),('20160217095229'),('20160217100536'),('20160218105235'),('20160219121836'),('20160222131559'),('20160223105040'),('20160223132539'),('20160223154009'),('20160223155557'),('20160303120458'),('20160307135036'),('20160309113850'),('20160309155638'),('20160310162232'),('20160408082534'),('20160504151342'),('20160504151626'),('20160505094646'),('20160513124317'),('20160517095615'),('20160517150444'),('20160531141452'),('20160824142312'),('20160912130902'),('20161010095349'),('20161011101739'),('20161027093957'),('20161124134422'),('20161129143629'),('20161129143735'),('20161130102656'),('20161208144901'),('20161212133015'),('20161212134619'),('20161213105545'),('20170117145632'),('20170124172923'),('20170215145129'),('20170301154749'),('20170309144237'),('20170309145516'),('20170321115012'),('20170406151110'),('20170602091314'),('20170607095453'),('20170711121424'),('20170717143912'),('20170717144002'),('20170829125634'),('20170920094317'),('20171006143805'),('20171010135127'),('20171011095056'),('20171025100714'),('20171026131121'),('20171107102053'),('20171128133429'),('20180117112653'),('20180117120616'),('20180122104144'),('20180122105511'),('20180122105804'),('20180122114153'),('20180122115427'),('20180122121232'),('20180125113031'),('20180205100124'),('20180205164153'),('20180205164203'),('20180205164213'),('20180205164611'),('20180207102508'),('20180213151824'),('20180316174049'),('20180410093814'),('20180419180203'),('20180429151412'),('20180612090556'),('20180612090557'),('20180803110015'),('20180815104210'),('20180815104230'),('20180815104231'),('20180815104232'),('20180913123624'),('20180918132758'),('20180919143203'),('20180924152253'),('20180925103340'),('20181011134514'),('20181102134542'),('20181109161058'),('20181113111833'),('20181128142428'),('20181210162148'),('20190403124116'),('20190408163210'),('20190409102235'),('20190409102407'),('20190410121245'),('20190410121821'),('20190410122522'),('20190426200617'),('20190426210303'),('20190428221140'),('20190712093046'),('20190712094906'),('20190730080909'),('20190829144713'),('20190913105005'),('20200117112757');
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
INSERT INTO `sessions` VALUES (1,'22134d221d8db3fa47f224aa94629825','BAh7BkkiEF9jc3JmX3Rva2VuBjoGRUZJIjExYlloNFZqNlg0aVQ4bmxzSnFy\nYi9sSHVhMXZkcldTQ25DUnNHdHNtZ3NjPQY7AEY=\n','2020-01-16 09:56:25','2020-01-16 09:56:31'),(2,'d5735e22704585305cba6ea3e6e29050','BAh7BkkiEF9jc3JmX3Rva2VuBjoGRUZJIjFGK2RqR3dydjhHRFhiYTVTY084\neGRDRnpOcjRtL2YxMTc3Y1FjTUl4SVNZPQY7AEY=\n','2020-01-16 09:56:31','2020-01-16 09:56:32'),(3,'20fad82b8d48f664902c651fe9200da8','BAh7CEkiEF9jc3JmX3Rva2VuBjoGRUZJIjFSSEVjOGx5NWsxY2VHOUthRFEz\nVDdTSzZUWW1iU1loZzI2elM2bG1aSnk4PQY7AEZJIgx1c2VyX2lkBjsARmkG\nSSITY2l0YXRpb25fc3R5bGUGOwBGSSIIYXBhBjsAVA==\n','2020-01-16 09:56:32','2020-01-16 10:14:37'),(4,'f0cbf1ba0fcbbf6a35bcc907e80537e2','BAh7B0kiEF9jc3JmX3Rva2VuBjoGRUZJIjF5V3VkRjJIaVlTM0xjR2VKTy80\nTFc3dWE1d3VaUlluOEVMNlNoMHpVWkU0PQY7AEZJIgx1c2VyX2lkBjsARmkG\n','2020-01-17 13:18:43','2020-01-17 13:19:13');
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
INSERT INTO `settings` VALUES (1,'css_prepended','--- \'\'\n',NULL,NULL,'2020-01-16 09:50:56','2020-01-16 09:50:56',NULL,NULL),(2,'css_appended','--- \'\'\n',NULL,NULL,'2020-01-16 09:50:56','2020-01-16 09:50:56',NULL,NULL),(3,'main_layout','--- application\n',NULL,NULL,'2020-01-16 09:50:56','2020-01-16 09:50:56',NULL,NULL),(4,'site_base_host','--- http://localhost:3000\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(5,'pubmed_api_email','--- sowen@cs.man.ac.uk\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(6,'crossref_api_email','--- sowen@cs.man.ac.uk\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(7,'bioportal_api_key','--- 6b28065a-f37b-46a4-b6de-99879700a14a\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(8,'sabiork_ws_base_url','--- http://sabiork.h-its.org/sabioRestWebServices/\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(9,'recaptcha_enabled','--- false\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(10,'recaptcha_private_key','--- \'\'\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(11,'recaptcha_public_key','--- \'\'\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(12,'default_associated_projects_access_type','--- 2\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(13,'default_all_visitors_access_type','--- 0\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(14,'max_all_visitors_access_type','--- 2\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(15,'permissions_popup','--- 0\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(16,'auth_lookup_update_batch_size','--- 10\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(17,'allow_private_address_access','--- false\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(18,'cache_remote_files','--- true\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(19,'max_cachable_size','--- 20971520\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(20,'hard_max_cachable_size','--- 104857600\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(21,'hide_details_enabled','--- false\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(22,'registration_disabled','--- false\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(23,'registration_disabled_description','--- Registration is not available, please contact your administrator\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(24,'activation_required_enabled','--- false\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(25,'orcid_required','--- false\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL),(26,'default_license','--- CC-BY-4.0\n',NULL,NULL,'2020-01-16 10:13:39','2020-01-16 10:13:39',NULL,NULL);
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
INSERT INTO `text_values` VALUES (1,NULL,NULL,'Microbiology','2020-01-16 09:50:36','2020-01-16 09:50:36'),(2,NULL,NULL,'Biochemistry','2020-01-16 09:50:36','2020-01-16 09:50:36'),(3,NULL,NULL,'Genetics','2020-01-16 09:50:36','2020-01-16 09:50:36'),(4,NULL,NULL,'Molecular Biology','2020-01-16 09:50:36','2020-01-16 09:50:36'),(5,NULL,NULL,'Bioinformatics','2020-01-16 09:50:36','2020-01-16 09:50:36'),(6,NULL,NULL,'Cheminformatics','2020-01-16 09:50:36','2020-01-16 09:50:36'),(7,NULL,NULL,'Mathematical Modelling','2020-01-16 09:50:36','2020-01-16 09:50:36'),(8,NULL,NULL,'Software Engineering','2020-01-16 09:50:36','2020-01-16 09:50:36'),(9,NULL,NULL,'Data Management','2020-01-16 09:50:36','2020-01-16 09:50:36'),(10,NULL,NULL,'Biochemistry and protein analysis','2020-01-16 09:50:36','2020-01-16 09:50:36'),(11,NULL,NULL,'Cell biology','2020-01-16 09:50:36','2020-01-16 09:50:36'),(12,NULL,NULL,'Cell and tissue culture','2020-01-16 09:50:36','2020-01-16 09:50:36'),(13,NULL,NULL,'Chemical modification','2020-01-16 09:50:36','2020-01-16 09:50:36'),(14,NULL,NULL,'Computational and theoretical biology','2020-01-16 09:50:36','2020-01-16 09:50:36'),(15,NULL,NULL,'Cytometry and fluorescent microscopy','2020-01-16 09:50:36','2020-01-16 09:50:36'),(16,NULL,NULL,'Genetic analysis','2020-01-16 09:50:36','2020-01-16 09:50:36'),(17,NULL,NULL,'Genetic modification','2020-01-16 09:50:36','2020-01-16 09:50:36'),(18,NULL,NULL,'Genomics','2020-01-16 09:50:36','2020-01-16 09:50:36'),(19,NULL,NULL,'Transcriptomics','2020-01-16 09:50:36','2020-01-16 09:50:36'),(20,NULL,NULL,'Proteomics','2020-01-16 09:50:36','2020-01-16 09:50:36'),(21,NULL,NULL,'Metabolomics','2020-01-16 09:50:36','2020-01-16 09:50:36'),(22,NULL,NULL,'Immunological techniques','2020-01-16 09:50:36','2020-01-16 09:50:36'),(23,NULL,NULL,'Isolation purification and separation','2020-01-16 09:50:36','2020-01-16 09:50:36'),(24,NULL,NULL,'Virology','2020-01-16 09:50:36','2020-01-16 09:50:36'),(25,NULL,NULL,'Model organisms','2020-01-16 09:50:36','2020-01-16 09:50:36'),(26,NULL,NULL,'Pharmacology and toxicology','2020-01-16 09:50:36','2020-01-16 09:50:36'),(27,NULL,NULL,'Spectroscopy and structural analysis','2020-01-16 09:50:36','2020-01-16 09:50:36'),(28,NULL,NULL,'Synthetic chemistry','2020-01-16 09:50:36','2020-01-16 09:50:36'),(29,NULL,NULL,'Single Cell analysis','2020-01-16 09:50:36','2020-01-16 09:50:36'),(30,NULL,NULL,'SBML','2020-01-16 09:50:36','2020-01-16 09:50:36'),(31,NULL,NULL,'ODE','2020-01-16 09:50:36','2020-01-16 09:50:36'),(32,NULL,NULL,'Partial differential equations','2020-01-16 09:50:36','2020-01-16 09:50:36'),(33,NULL,NULL,'Algebraic equations','2020-01-16 09:50:36','2020-01-16 09:50:36'),(34,NULL,NULL,'Linear equations','2020-01-16 09:50:36','2020-01-16 09:50:36'),(35,NULL,NULL,'Agent-based modelling','2020-01-16 09:50:36','2020-01-16 09:50:36'),(36,NULL,NULL,'Databases','2020-01-16 09:50:36','2020-01-16 09:50:36'),(37,NULL,NULL,'Java','2020-01-16 09:50:36','2020-01-16 09:50:36'),(38,NULL,NULL,'Perl','2020-01-16 09:50:36','2020-01-16 09:50:36'),(39,NULL,NULL,'Python','2020-01-16 09:50:36','2020-01-16 09:50:36'),(40,NULL,NULL,'Copasi','2020-01-16 09:50:36','2020-01-16 09:50:36'),(41,NULL,NULL,'JWS Online','2020-01-16 09:50:36','2020-01-16 09:50:36'),(42,NULL,NULL,'Workflows','2020-01-16 09:50:36','2020-01-16 09:50:36'),(43,NULL,NULL,'Web services','2020-01-16 09:50:36','2020-01-16 09:50:36'),(44,NULL,NULL,'Matlab','2020-01-16 09:50:36','2020-01-16 09:50:36'),(45,NULL,NULL,'Mathematica','2020-01-16 09:50:37','2020-01-16 09:50:37'),(46,NULL,NULL,'Fermentation','2020-01-16 09:50:37','2020-01-16 09:50:37'),(47,NULL,NULL,'PCR','2020-01-16 09:50:37','2020-01-16 09:50:37'),(48,NULL,NULL,'rtPCR','2020-01-16 09:50:37','2020-01-16 09:50:37'),(49,NULL,NULL,'qtPCR','2020-01-16 09:50:37','2020-01-16 09:50:37'),(50,NULL,NULL,'Microarray analysis','2020-01-16 09:50:37','2020-01-16 09:50:37'),(51,NULL,NULL,'Chip-chip','2020-01-16 09:50:37','2020-01-16 09:50:37'),(52,NULL,NULL,'R','2020-01-16 09:50:37','2020-01-16 09:50:37'),(53,NULL,NULL,'Mass spectrometry','2020-01-16 09:50:37','2020-01-16 09:50:37'),(54,NULL,NULL,'Chromatography','2020-01-16 09:50:37','2020-01-16 09:50:37'),(55,NULL,NULL,'Cell designer','2020-01-16 09:50:37','2020-01-16 09:50:37'),(56,NULL,NULL,'Cytoscape','2020-01-16 09:50:37','2020-01-16 09:50:37');
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
INSERT INTO `units` VALUES (23502095,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mg/g_DW','specific concentration per gram of dry weigh biomass',0,160),(44525432,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µL','microlitre',1,30),(128569078,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','g/g_DW','specific concentration per gram of dry weigh biomass',0,150),(131849255,'micrometer','2020-01-16 09:50:40','2020-01-16 09:50:41','µm','micrometer',1,440),(149472063,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','g/L','concentration per litre of corresponding comparment',1,140),(213119659,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','CFU/g','colony forming units per gram',0,300),(246812680,'month','2020-01-16 09:50:40','2020-01-16 09:50:40','mo','time',1,370),(265110944,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','sec-1','rate',0,410),(272102031,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µg/µl','concentration - microgram per microlitre',0,260),(303251610,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','min-1','rate',0,400),(346900202,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','muMol/g_DW','specific concentration per gram of dry weigh biomass',0,170),(370706647,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','°C','Celcius',1,450),(407965186,'meter','2020-01-16 09:50:40','2020-01-16 09:50:41','m','metre',0,420),(422566778,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mol','amount of substance',1,90),(434584122,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mM','concentration per litre of corresponding comparment',1,110),(443536035,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','M','concentration per litre of corresponding comparment',1,100),(444567680,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','ng','nanogram',1,70),(458910145,'week','2020-01-16 09:50:40','2020-01-16 09:50:40','wk','time',1,360),(490137447,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µg','microgram',1,60),(491343564,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','dimensionless','dimensionless',1,500),(512992492,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','a.u.','arbitrary units',1,490),(522578845,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','g','gram',1,40),(543902373,'minute','2020-01-16 09:50:40','2020-01-16 09:50:40','min','time',1,330),(563700913,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mmol/g_DW','specific concentration per gram of dry weigh biomass',0,180),(565608506,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','%','percentage',1,480),(582320163,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µmol/L','specific concentration per litre',0,230),(623964288,'centimeter','2020-01-16 09:50:40','2020-01-16 09:50:40','cm','centimeter',1,430),(627782146,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µM','concentration per litre of corresponding comparment',1,120),(630689200,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mg','milligram',1,50),(631253395,'day','2020-01-16 09:50:40','2020-01-16 09:50:40','d','time',1,350),(641184289,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mg/ml','concentration - milligram per millilitre',0,240),(646665765,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','pM','concentration per litre of corresponding comparment',1,130),(737472028,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mmol/L','specific concentration per litre',0,220),(787278530,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mmol/L_CV','specific concentration per litre of cytoplasmic volume',0,200),(802556390,'second','2020-01-16 09:50:40','2020-01-16 09:50:40','s','time',1,320),(803707897,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','L','litre',1,10),(807276879,'hour','2020-01-16 09:50:40','2020-01-16 09:50:40','h','time',1,340),(817866611,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','CFU','colony forming units',0,290),(872939841,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','rpm','revolutions per minute',1,470),(875082334,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','CFU/ml','colony forming units per millilitre',0,310),(879196749,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','h-1','rate',0,390),(879914886,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µg/ml','concentration - microgram per milliltre',0,250),(922717355,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','bar','headspace pressure',1,460),(923869648,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µmol/(g_DW*min)','specific rate per gram of dry weigh biomass',0,210),(955952038,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','µmol/L_CV','specific concentration per litre of cytoplasmic volume',0,190),(977236310,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mL','millilitre',1,20),(998404921,'year','2020-01-16 09:50:40','2020-01-16 09:50:40','yr','time',1,380),(1010822691,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','pg','picogram',1,80),(1028274690,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','L/min','flow rate',1,270),(1052799941,NULL,'2020-01-16 09:50:40','2020-01-16 09:50:40','mL/min','flow rate',1,280);
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
INSERT INTO `users` VALUES (1,'huxg','3190eeac8d714696a7463e747edc39ba6db7c501fd0cd400bb5cd14563715f02','26be52b8d67aa6c2d01c461f04f37fb7b4e5f4ac','2020-01-16 09:55:49','2020-01-16 09:55:50',NULL,NULL,NULL,'2020-01-16 09:55:49',1,NULL,NULL,0,NULL,'4c5617c0-1a74-0138-a941-2cde48001122');
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_groups`
--

LOCK TABLES `work_groups` WRITE;
/*!40000 ALTER TABLE `work_groups` DISABLE KEYS */;
INSERT INTO `work_groups` VALUES (1,NULL,1,1,'2020-01-16 09:50:38','2020-01-16 09:50:38'),(2,NULL,2,2,'2020-01-16 09:55:50','2020-01-16 09:55:50');
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

-- Dump completed on 2020-01-17 14:20:44
