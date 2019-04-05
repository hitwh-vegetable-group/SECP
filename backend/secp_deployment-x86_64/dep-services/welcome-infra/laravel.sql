-- License: GNU AGPL v3.0
-- Author: HITwh Vegetable Group :: ArHShRn

CREATE USER 'laravel'@'localhost' IDENTIFIED BY 'laravel';
CREATE DATABASE `laravel` default character set utf8 collate utf8_general_ci;

grant all on laravel.* to laravel@'localhost' identified by 'laravel' with grant option;
flush privileges;
