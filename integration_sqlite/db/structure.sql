PRAGMA foreign_keys = ON;
PRAGMA defer_foreign_keys = ON;

-- Tables

CREATE TABLE posts (
  id integer,
  user_id integer,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE TABLE users (
  id integer,
  email text,
  PRIMARY KEY (id)
);