
use actix_web::{middleware, web, App, HttpServer, HttpResponse, get, post, Responder};
use actix_files::Files;

//use json::JsonValue;

use serde::{Deserialize, Serialize};


use std::collections::HashMap;
use std::sync::RwLock;
use std::env;
use rand::Rng;
use chrono::Utc;



#[allow(dead_code)]
struct Model {
    database: HashMap<String, String>,
    messages: RwLock<Vec<DatedMessage>>,
    sessions: HashMap<String, SentLogin>,
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


#[allow(dead_code)]
#[derive(Deserialize)]
struct Login {
    #[serde(rename = "authType")]
    auth_type: String,
    username: String,
    password: String,
}


fn get_random_bytes() -> String {
    let random_bytes: [u8; 16] = rand::thread_rng().gen::<[u8; 16]>();
    hex::encode(random_bytes)
}


fn init_map() -> HashMap<String, String> {
    let mut database: HashMap<String, String> = HashMap::new();
    database.insert("stéén".to_string(), "2".to_string());
    database.insert("lamkas".to_string(), "1".to_string());
    database
}


#[get("/message")]
async fn get_message(model: web::Data<Model>) -> impl Responder {
    let msg  = &*model.messages.read().unwrap();
    HttpResponse::Ok().json(msg)
}

#[post("/message")]
async fn post_message(message: web::Json<Message>, model: web::Data<Model>) -> impl Responder {
    //let mut lock = model.inner().messages.write().expect("lock message vector");
    
    let mut lock = model.messages.write().expect("lock message vector");
    let msg = message.into_inner();

    lock.push(DatedMessage {
        username: msg.username,
        color: msg.color,
        text: msg.text,
        created_at: Utc::now().timestamp_millis() as u64,
    });

    HttpResponse::Ok().body("Success")
}


#[post("/login")]
async fn login(logininfo: web::Json<Login>, model: web::Data<Model>) -> impl Responder {
    let status: i32;
    let mut username = None;
    let mut id = None;

    print!("gets here !!!!!");


    match model.database.get(&logininfo.username) {
        Some(psw) if psw == &logininfo.password => {
            status = 1;
            username = Some(logininfo.into_inner().username);
            id = Some(get_random_bytes());
        }
        Some(_) => status = -1,
        None => status = -2,
    }


    HttpResponse::Ok().json(SentLogin {
        id,
        username,
        status,
    })
}

fn get_static_files() -> String {
    env::args().nth(1).unwrap_or_else(|| String::from("../client-elm/public"))
}

#[actix_rt::main]
async fn main() -> std::io::Result<()> {
    std::env::set_var("RUST_LOG", "actix_web=info");
    env_logger::init();

    println!("http://127.0.0.1:8080");


    HttpServer::new(|| {
        App::new()
        .data(Model{
            database: init_map(),
            messages: RwLock::new(Vec::new()),
            sessions: HashMap::new(),
        })
            // enable logger
        .wrap(middleware::Logger::default())
        .service(get_message)
        .service(post_message)
        .service(login)
        .service(Files::new("/", get_static_files()).index_file("index.html"))
        
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::dev::Service;
    use actix_web::{http, test, web, App, Error};

    #[actix_rt::test]
    async fn test_index() -> Result<(), Error> {
        let app = App::new().route("/", web::get().to(index));
        let mut app = test::init_service(app).await;

        let req = test::TestRequest::get().uri("/").to_request();
        let resp = app.call(req).await.unwrap();

        assert_eq!(resp.status(), http::StatusCode::OK);

        let response_body = match resp.response().body().as_ref() {
            Some(actix_web::body::Body::Bytes(bytes)) => bytes,
            _ => panic!("Response error"),
        };

        assert_eq!(response_body, r##"Hello world!"##);

        Ok(())
    }
}
