-- Tables

CREATE TABLE posts (
  id integer,
  user_id integer NOT NULL,
  title text NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE users (
  id integer,
  email text NOT NULL,
  PRIMARY KEY (id)
);

-- Indexes
CREATE INDEX "idx_posts_user_id" ON "posts" ("user_id");