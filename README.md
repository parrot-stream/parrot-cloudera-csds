## **Parrot Cloudera CSDs!**

This project contains the Cloudera **Custom Service Descriptors** (CSD) for all the Parrot Stream distribution components.

These includes:

- **SCHEMA_REGISTRY**: the [Confluent Schema Registry](http://docs.confluent.io/current/schema-registry/docs/index.html), v3.2.2
- **KAFKA_REST**: the [Confluent Kafka REST Proxy](http://docs.confluent.io/current/kafka-rest/docs/index.html), v3.2.2
- **PARROT_STREAM**: includes [Confluent Kafka Connect](http://docs.confluent.io/current/connect/index.html), v3.2.2, with no additional connectors
- **PARROT_MANAGER**: includes the Management UIs for the Schema Registry, Kafka Topics and Kafka Connect

### **Build**

#### **Prerequisites**

- Maven 3.2.x

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

Finally restart the Cloudera Management Service in the Cloudera Admin Console.
You can find more detailed instruction on the [Cloudera Add-on Services](https://www.cloudera.com/documentation/enterprise/5-11-x/topics/cm_mc_addon_services.html) documentation.

To be able to configure and add the Parrot Stream services you must then **download**, **distribute** and **activate** the Parrot Stream parcels.
To do that you can go to the Parcels section in the Cloudera Admin Console ( `Hosts -> Parcels` ).

Some of the Parrot services depends on other **CDH** services and they depends on each other. Following is the dependency matrix:

| Parrot Service    | Depends on      |
|-------------------|-----------------|
| SCHEMA_REGISTRY   | ZOOKEEPER       |
|                   | KAFKA           |
| KAFKA_REST        | SCHEMA_REGISTRY |
|                   | KAFKA           |
| PARROT_STREAM     | SCHEMA_REGISTRY |
|                   | KAFKA           |
| PARROT_MANAGER    | SCHEMA_REGISTRY |
|                   | KAFKA_REST      |
|                   | PARROT_STREAM   |



