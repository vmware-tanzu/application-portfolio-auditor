use std::env;
use handlebars::Handlebars;
use std::collections::HashMap;
use std::error::Error;
use std::path::Path;

fn main() -> Result<(), Box<dyn Error>> {
    // Get command line arguments
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <template_file> <partial1> <partial2> ... <variable_file>", args[0]);
        return Ok(());
    }

    let template_file = &args[1];
    let partials: Vec<&str> = args[2..args.len()].iter().map(|s| s.as_str()).collect();
    let variable_file = &args[args.len() - 1];

    let mut handlebars = Handlebars::new();
    // Load template file
    handlebars.register_template_file("main_template", template_file)?;
    // Load partials
    for partial in &partials {
        // Get the name of the partial file without extension from the path
        let partial_stem = Path::new(partial)
            .file_stem()
            .and_then(|f| f.to_str())
            .unwrap_or_default();
        handlebars.register_template_file(partial_stem, partial)?;
    }

    // Load variables from property file
    let mut variables = HashMap::new();
    let variable_content = std::fs::read_to_string(variable_file)?;
    for line in variable_content.lines() {
        let mut parts = line.splitn(2, '=');
        if let (Some(key), Some(value)) = (parts.next(), parts.next()) {
            variables.insert(key.trim().to_string(), value.trim().to_string());
        }
    }

    // Render template
    handlebars.register_escape_fn(handlebars::no_escape); // Disable HTML escaping
    println!("{}", handlebars.render("main_template", &variables)?);

    Ok(())
}
