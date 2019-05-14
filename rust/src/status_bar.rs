extern crate crossterm;

use crossterm::{ cursor, terminal, Colored, Color, Attribute };


pub struct StatusBar {
    pub line_number: u32,
    pub file: String,
    pub revision: String
}

impl StatusBar {
    pub fn draw(&self) {
        let curs = cursor();
        let (width, height) = terminal().terminal_size();

        curs.save_position();
        curs.goto(0, height);
        let term = terminal();


        print!("{}", Colored::Bg(Color::White));
        print!("{}", Colored::Fg(Color::Black));
        term.write(&self.file);
        term.write(":");
        term.write(self.line_number);
        term.write("@");
        term.write(&self.revision);

        term.write(" ".repeat(usize::from(width - curs.pos().0)));
        print!("{}", Attribute::Reset);


        std::thread::sleep(std::time::Duration::from_millis(1000));


        curs.reset_position();
    }
}
