## **Parrot Cloudera CSDs!**



This project contains the Cloudera **Custom Service Descriptors** (CSD) for all the Parrot Distribution components.

### **Build**

#### **Prerequisites**

- Maven 3.2.x (or greater)

#### **Command**

    ./parrot-csd build
   
### **Installation**

#### **Command**

To install in the Cloudera default directory `/opt/cloudera/csd`:

    ./parrot-csd install

To install in a specific directory which has to be configured in the Cloudera Admin console:

    ./parrot-csd install -d=INSTALL_DIR

Restart the Cloudera Manager Server:
    
        sudo service cloudera-scm-server restart

Finally restart the Cloudera Management Service in the Cloudera Admin Console

You can find more detailed instruction on the [Cloudera Add-on Services](https://www.cloudera.com/documentation/enterprise/5-11-x/topics/cm_mc_addon_services.html) documentation.

To be able to configure and use the Added service you must now **download**, **distribute** and **activate** the Parrot parcels.
To do that you can go to the Parcels section in the Cloudera Admin Console ( `Hosts -> Parcels` ).

Some of the Parrot services depends on other **CDH** services. Following is the dependency matrix:

| Parrot service    | Depends on      | Version   |
|-------------------|-----------------|-----------|
| SCHEMA_REGISTRY   | ZOOKEEPER       ||
| SCHEMA_REGISTRY_UI| SCHEMA_REGISTRY ||
| KAFKA_REST        | KAFKA           |`>= 2.2.0`  |
| KAFKA_TOPICS_UI   | KAFKA           |`>= 2.2.0` |
| PARROT            | KAFKA           |`>= 2.2.0` |
| KAFKA_CONNECT_UI  | PARROT          ||

