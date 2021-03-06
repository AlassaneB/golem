golem_sys <- function(
  ..., 
  lib.loc = NULL, 
  mustWork = FALSE
){
  system.file(
    ..., 
    package = "golem", 
    lib.loc = lib.loc, 
    mustWork = mustWork
  )
}

#  from usethis https://github.com/r-lib/usethis/
darkgrey <- function(x) {
  x <- crayon::make_style("darkgrey")(x)
}

#' @importFrom fs dir_exists file_exists
dir_not_exist <- Negate(dir_exists)
file_not_exist <- Negate(file_exists)

#' @importFrom fs dir_create file_create
create_if_needed <- function(
  path, 
  type = c("file", "directory"),
  content = NULL
){
  type <- match.arg(type)
  # Check if file or dir already exist
  if (type == "file"){
    dont_exist <- file_not_exist(path)
  } else if (type == "directory"){
    dont_exist <- dir_not_exist(path)
  }
  # If it doesn't exist, ask if we are allowed 
  # to create it
  if (dont_exist){
    ask <- yesno(
      sprintf(
        "The %s %s doesn't exist, create?", 
        basename(path), 
        type
      )
    )
    # Return early if the user doesn't allow 
    if (!ask) {
      return(FALSE)
    } else {
      # Create the file 
      if (type == "file"){
        file_create(path)
        write(content, path, append = TRUE)
      } else if (type == "directory"){
        dir_create(path, recurse = TRUE)
      }
    }
  } 
  
  # TRUE means that file exists (either 
  # created or already there)
  return(TRUE)
}

#' @importFrom fs file_exists
check_file_exist <- function(file){
  res <- TRUE
  if (file_exists(file)){
    res <- yesno("This file already exists, override?")
  }
  return(res)
}

# TODO Remove from codebase
#' @importFrom fs dir_exists
check_dir_exist <- function(dir){
  res <- TRUE
  if (!dir_exists(dir)){ 
    res <- yesno(sprintf("The %s does not exists, create?", dir))
  }
  return(res)
}

# internal
replace_word <- function(file,pattern, replace){
  suppressWarnings( tx  <- readLines(file) )
  tx2  <- gsub(pattern = pattern, replacement = replace, x = tx)
  writeLines(tx2, con=file)
}

remove_comments <- function(file) {
  lines <- readLines(file)
  lines_without_comment <- c()
  for ( line in lines ) {
    lines_without_comment <- append(
      lines_without_comment, 
      gsub("(\\s*#+[^'@].*$| #+[^#].*$)", "", line)
    )
  }
  lines_without_comment <- lines_without_comment[lines_without_comment != ""]
  writeLines(text = lines_without_comment, con = file)
}

#' @importFrom cli cat_bullet
cat_green_tick <- function(...){
  cat_bullet(
    ..., 
    bullet = "tick", 
    bullet_col = "green"
  )
}

#' @importFrom cli cat_bullet
cat_red_bullet <- function(...){
  cat_bullet(
    ..., 
    bullet = "bullet",
    bullet_col = "red"
  )
}

#' @importFrom cli cat_bullet
cat_info <- function(...){
  cat_bullet(
    ..., 
    bullet = "arrow_right",
    bullet_col = "grey"
  )
}

cat_exists <- function(where){
  cat_red_bullet(
    sprintf(
      "%s already exists, skipping the copy.", 
      path_file(where)
    )
  )
  cat_info(
    sprintf(
      "If you want replace it, remove the %s file first.", 
      path_file(where)
    )
  )
}

cat_created <- function(
  where, 
  file = "File"
){
  cat_green_tick(
    sprintf(
      "%s created at %s",
      file, 
      where
    )
  )
}

# File made dance

cat_automatically_linked <- function(){
  cat_green_tick(
    'File automatically linked in `golem_add_external_resources()`.'
  )
}

open_or_go_to <- function(
  where,
  open
){
  if (
    rstudioapi::isAvailable() && 
    open && 
    rstudioapi::hasFun("navigateToFile")
  ){
    rstudioapi::navigateToFile(where)
  } else {
    cat_red_bullet(
      sprintf(
        "Go to %s", 
        where
      )
    )
  }
}

desc_exist <- function(pkg){
  file_exists(
    paste0(pkg, "/DESCRIPTION")
  )
}

after_creation_message_js <- function(
  pkg, 
  dir, 
  name
){
  if (
    desc_exist(pkg)
  ) {
    if ( 
      fs::path_abs(dir) != fs::path_abs("inst/app/www") & 
      packageVersion("golem") < "0.2.0"
    ){
      cat_red_bullet(
        sprintf(
          'To link to this file, go to the `golem_add_external_resources()` function in `app_ui.R` and add `tags$script(src="www/%s.js")`', 
          name
        )
      )
    } else {
      cat_automatically_linked()
    }
  }
}
after_creation_message_css <- function(
  pkg, 
  dir, 
  name
){
  if (
    desc_exist(pkg)
  ) {
    if (fs::path_abs(dir) != fs::path_abs("inst/app/www") & 
        packageVersion("golem") < "0.2.0"
    ){
      cat_red_bullet(
        sprintf(
          'To link to this file,  go to the `golem_add_external_resources()` function in `app_ui.R` and add `tags$link(rel="stylesheet", type="text/css", href="www/.css")`', 
          name
        )
      )
    } else {
      cat_automatically_linked()
    }
  }
}

file_created_dance <- function(
  where, 
  fun, 
  pkg, 
  dir, 
  name, 
  open
){
  cat_created(where)
  
  fun(pkg, dir, name)
  
  open_or_go_to(where, open)
}

# Minor toolings

if_not_null <- function(x, ...){
  if (! is.null(x)){
    force(...)
  }
}

set_name <- function(x, y){
  names(x) <- y
  x
}

# FROM tools::file_path_sans_ext() & tools::file_ext
file_path_sans_ext <- function(x){
  sub("([^.]+)\\.[[:alnum:]]+$", "\\1", x)
}

file_ext <- function (x) {
  pos <- regexpr("\\.([[:alnum:]]+)$", x)
  ifelse(pos > -1L, substring(x, pos + 1L), "")
}
