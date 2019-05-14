extern crate crossterm;

use crossterm::{ RawScreen, ClearType, terminal };
use std::io;
use std::io::prelude::*;
use std::fs::File;
use std::env;
use std::process::exit;


mod status_bar;
use status_bar::StatusBar;

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        println!("Usage: git spelunk FILE");
        exit(1);
    }

    let file = args[1].clone();
    let mut status_bar = StatusBar {
        line_number: 1,
        file: file,
        revision: "hello!".to_string()
    };

    let screen = RawScreen::into_raw_mode();

    let mut f = File::open("Cargo.toml")?;
    let mut buffer = String::new();
    f.read_to_string(&mut buffer)?;

    terminal().clear(ClearType::All);

    status_bar.draw();
    Ok(())
}
