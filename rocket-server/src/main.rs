#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate rocket;
/*
use rocket::response::NamedFile;
use std::path::{PathBuf, Path}; 
*/
use rocket_contrib::json;
use rocket_contrib::serve::StaticFiles;

use serde::{Deserialize, Serialize};
use rocket::State;

use rand::Rng;

use std::collections::HashMap;
use chrono::Utc;

use std::sync::Mutex;

use std::env;

#[allow(dead_code)]
struct Model {
    database: HashMap<String, String>,
    messages: Mutex<Vec<DatedMessage>>,
    sessions: HashMap<String, SentLogin>
}


#[allow(non_snake_case)]
#[derive(Serialize)]
struct DatedMessage {
    username: String,
    color: String,
    text: String,
    createdAt: u32,
}

#[allow(non_snake_case)]
#[derive(Deserialize)]
struct Message {
    username: String,
    color: String,
    text: String,
}


#[get("/message")]
fn get_message(model: State<Model>) -> json::JsonValue {
    let msg = model.inner().messages.lock().unwrap();
    json!(*msg)
}


#[post("/message", format = "application/json", data = "<message>")]
fn post_message(message: json::Json<Message>, model: State<Model>) -> String {

    let mut lock = model.inner().messages.lock().expect("lock message vector");

    lock.push(DatedMessage {
        username: message.username.clone(),
        color: message.color.clone(),
        text: message.text.clone(),
        createdAt: Utc::now().timestamp_millis() as u32,
    });
    
    "Success".to_string()
}


#[allow(dead_code)]
#[allow(non_snake_case)]
#[derive(Deserialize)]
struct Login {
    authType: String,
    username: String,
    password: String,
}

#[allow(non_snake_case)]
#[derive(Serialize)]
struct SentLogin {
    id: String,
    username: String,
    status: i32,
}

fn get_random_bytes () -> String {
    let random_bytes: [u8; 16] = rand::thread_rng().gen::<[u8; 16]>();
    hex::encode(random_bytes)
}


#[post("/login", format = "application/json", data = "<logininfo>")]
fn login (logininfo: json::Json<Login>, model: State<Model>) -> json::Json<SentLogin> {

    let status: i32;
    let mut username = "".to_string();
    let mut id = "".to_string();
    let db = &model.database;

    match db.get(&logininfo.username)  {
        Some(psw) => {
            if psw == &logininfo.password {
                status = 1;
                username = logininfo.username.clone();
                id = get_random_bytes();
            }
            else {
                status = -1;
            }
        },
        None => {
            status = -2;
        },
 
    }

    json::Json(SentLogin {
        id,
        username,
        status,
    })
}


fn init_map () -> HashMap<String, String> {
    let mut database: HashMap<String, String> =  HashMap::new();
    database.insert("stéén".to_string(), "2".to_string());
    database.insert("lamkas".to_string(), "1".to_string());
    return database;
}

fn main() {
    let static_files =  match env::args().nth(1) {
        Some(path) => path,
        _ => "../client-elm/public".to_string(),
    };

    println!("{}", static_files);

    rocket::ignite()
    .manage(Model {
        database: init_map(),
        messages: Mutex::new(Vec::new()),
        sessions: HashMap::new(),
    })
    .mount("/", StaticFiles::from(static_files))
    .mount("/", routes![login, post_message, get_message]).launch();
}
