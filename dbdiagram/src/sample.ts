export const SAMPLE_DBML = `Table users {
  id int [pk]
  name varchar
  email varchar [unique, not null]
}

Table posts {
  id int [pk]
  title varchar
  body text
  user_id int [ref: > users.id]
}

Table comments {
  id int [pk]
  body text
  user_id int [ref: > users.id]
  post_id int [ref: > posts.id]
}
`;
