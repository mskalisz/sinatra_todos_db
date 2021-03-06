CREATE TABLE lists (
    id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name text UNIQUE NOT NULL
);

 CREATE TABLE todos (
    id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    completed boolean NOT NULL DEFAULT false,
    list_id int NOT NULL REFERENCES lists(id)
);