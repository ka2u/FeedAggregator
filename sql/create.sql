CREATE TABLE users (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL UNIQUE,
    passwd VARCHAR(20) NOT NULL,
    mail VARCHAR(30) NOT NULL
);

CREATE TABLE feeds (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    foldertitle VARCHAR(512) NOT NULL,
    feedtitle VARCHAR(512) NOT NULL,
    title VARCHAR(512) NOT NULL,
    creator VARCHAR(256) NOT NULL,
    link VARCHAR(512) NOT NULL,
    guid VARCHAR(512) NOT NULL,
    itemid VARCHAR(256) NOT NULL,
    pubdate TIMESTAMP,
    timestamp TIMESTAMP
);

INSERT INTO users (user_id, passwd, mail) VALUES ('ka2u', 'Password', 'stevenlabs@gmail.com');
INSERT INTO feeds (foldertitle, feedtitle, title, creator, link, guid, itemid, pubdate, timestamp) VALUES ('first', 'first', 'first', 'first', 'http://example.com', 'http://example.com', '0', '00-00-00 00:00:00', '00-00-00 00:00:00');
