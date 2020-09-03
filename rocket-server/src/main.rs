#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate rocket;
use rocket_contrib::json;
use rocket_contrib::serve::StaticFiles;
use rocket::State;
use serde::{Deserialize, Serialize};
use rand::Rng;
use chrono::Utc;
use std::collections::HashMap;
use std::sync::RwLock;
use std::env;

#[allow(dead_code)]
struct Model {
    database: HashMap<String, String>,
    messages: RwLock<Vec<DatedMessage>>,
    sessions: HashMap<String, SentLogin>,
}

#[derive(Serialize)]
struct DatedMessage {
    username: String,
    color: String,
    text: String,
    #[serde(rename = "createdAt")]
    created_at: u64,
}

#[derive(Deserialize)]
struct Message {
    username: String,
    color: String,
    text: String,
}

#[get("/message")]
fn get_message(model: State<Model>) -> json::JsonValue {
    let msg = model.inner().messages.read().unwrap();
    json!(*msg)
}

#[post("/message", format = "application/json", data = "<message>")]
fn post_message(message: json::Json<Message>, model: State<Model>) -> &'static str {
    let mut lock = model.inner().messages.write().expect("lock message vector");

    let msg = message.into_inner();

    lock.push(DatedMessage {
        username: msg.username,
        color: msg.color,
        text: msg.text,
        created_at: Utc::now().timestamp_millis() as u64,
    });

    "Success"
}

#[allow(dead_code)]
#[derive(Deserialize)]
struct Login {
    #[serde(rename = "authType")]
    auth_type: String,
    username: String,
    password: String,
}

#[allow(non_snake_case)]
#[derive(Serialize)]
struct SentLogin {
    #[serde(skip_serializing_if = "Option::is_none")]
    id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    username: Option<String>,
    status: i32,
}

fn get_random_bytes() -> String {
    let random_bytes: [u8; 16] = rand::thread_rng().gen::<[u8; 16]>();
    hex::encode(random_bytes)
}

#[post("/login", format = "application/json", data = "<logininfo>")]
fn login(logininfo: json::Json<Login>, model: State<Model>) -> json::Json<SentLogin> {
    let status: i32;
    let mut username = None;
    let mut id = None;

    
    match model.database.get(&logininfo.username) {
        Some(psw) if psw == &logininfo.password => {
            status = 1;
            username = Some(logininfo.into_inner().username);
            id = Some(get_random_bytes());
        }
        Some(_) => status = -1,
        None => status = -2,
    }

    json::Json(SentLogin {
        id,
        username,
        status,
    })
}

fn init_map() -> HashMap<String, String> {
    let mut database: HashMap<String, String> = HashMap::new();
    database.insert("stéén".to_string(), "2".to_string());
    database.insert("lamkas".to_string(), "1".to_string());
    database
}

fn main() {
    let static_files = env::args().nth(1).unwrap_or_else(|| "../client-elm/public".to_string());
    println!("{}", static_files); 


    let error = rocket::ignite()
        .manage(Model {
            database: init_map(),
            messages: RwLock::new(Vec::new()),
            sessions: HashMap::new(),
        })
        .mount("/", StaticFiles::from(static_files))
        .mount("/", routes![login, post_message, get_message])
        .launch();

    print!("Something went wrong {}", error);
}