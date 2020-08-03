-- .mode csv

create table Dish(
    name varchar(255) null,
    id integer PRIMARY KEY asc not null,
    menus_appeared integer not null,
    times_appeared integer not null,
    first_appeared datetime not null,
    last_appeared datetime not null,
    lowest_price decimal(10, 2) null,
    highest_price decimal(10, 2) null
);

-- .import ./NYPL-Menus/Dish_Clean_Final.csv Dish

create table Menu(
    id integer primary key asc not null,
    name varchar(255) null,
    sponsor varchar(255) null,
    event varchar(255) null,
    venue varchar(255) null,
    place varchar(255) null,
    physical_description varchar(255) null,
    occasion varchar(255) null,
    notes text null,
    call_number varchar(255) null,
    date DATE,
    location varchar(255) null,
    currency varchar(255) null,
    currency_symbol varchar(255) null,
    status varchar(255) null,
    page_count integer,
    dish_count integer
);

-- .import ./NYPL-Menus/Menu_Clean_Final.csv Menu

create table MenuPage(
    id integer primary key asc not null,
    menu_id integer not null,
    page_number integer,
    image_id integer,
    full_height integer,
    full_width integer,
    uuid varchar(255),
    FOREIGN KEY(menu_id) REFERENCES  Menu(id)
 
);

-- .import ./NYPL-Menus/MenuPage_Clean_Final.csv MenuPage

Create table MenuItem(
    id integer primary key asc not null,
    menu_page_id integer not null,
    price decimal(10, 2) null,
    high_price decimal(10, 2) null,
    dish_id integer no null,
    created_at datetime not null,
    update_at datetime not null,
    xpos decimal(1, 6),
    ypos decimal(1, 6),
    FOREIGN KEY(menu_page_id) REFERENCES  MenuPage(id),
    FOREIGN KEY(dish_id) REFERENCES  Dish(id)

);

-- .import ./NYPL-Menus/MenuItem_Clean_Final.csv MenuItem

-- enforce referential integrity
select count(*) from menuitem where dish_id not in (select id from dish);
-- remove 37642 from where there is no dish for the menu item
delete from menuitem where dish_id not in (select id from dish);

-- remoe 47937 where there is no menu for menu page
select count(*) from menupage where menu_id not in (select id from menu);
delete from menupage where menu_id not in (select id from menu);

-- remove 1526 where no menu page for menu item
select count(*) from menuitem where menu_page_id not in (select id from menupage);
delete from menuitem where menu_page_id not in (select id from menupage);


-- price not must be higher than high price
select count(*) from menuitem where id in (select id from menuitem where price > high_price);

-- update 1268 rows where price was greater than high price
update menuitem set high_price = price where id in (select id from menuitem where price > high_price);


select id, price, high_price from menuitem where price > high_price;



-- the count of the  dish id in menu items must be equal to times appeared
select count(*) from (
    select dish_id
    from MenuItem
    join dish on MenuItem.dish_id = dish.id
    group by dish_id, name
    having count(dish_id) != dish.times_appeared
)

-- update 6684 dishes times appeared to enforce IC to match data

update dish set times_appeared = coalesce((
  
    select coalesce(count(dish_id), 0) as cnt
    from MenuItem 
    where dish_id = dish.id
    group by dish_id
), 0) where id in (
    select dish_id
    from MenuItem
    join dish on MenuItem.dish_id = dish.id
    group by dish_id, name
    having count(dish_id) != dish.times_appeared
);

select dish_id, name, count(dish_id), times_appeared
from MenuItem
join dish on MenuItem.dish_id = dish.id
group by dish_id, name
having count(dish_id) != dish.times_appeared;


-- the low price of a dish must be equal to the lowest price from menu item
select count(*) from (
    select dish_id
    from dish
    join menuitem on menuitem.dish_id = dish.id
    group by dish_id
    having min(menuitem.price) != dish.lowest_price
);

-- update 2294 dish items to have lowest prices that matches the data
update dish set lowest_price = coalesce((
    select min(menuitem.price)
    from menuitem
    where dish_id = dish.id
    group by dish_id
    having min(menuitem.price) != dish.lowest_price
), 0) where id in (
    select dish_id
    from dish
    join menuitem on menuitem.dish_id = dish.id
    group by dish_id
    having min(menuitem.price) != dish.lowest_price
);

select dish_id, name, dish.lowest_price, min(menuitem.price) from dish
join menuitem on menuitem.dish_id = dish.id
group by dish_id, name
having min(menuitem.price) != dish.lowest_price;



----
-- the highest price of a dish must equal to the highest price from menu item
select count(*) from (
    select dish_id
    from dish
    join menuitem on menuitem.dish_id = dish.id
    group by dish_id
    having max(menuitem.price) != dish.highest_price
);

-- update 24394 dish items to have highest prices that matches the data to enforce IC
update dish set highest_price = coalesce((
    select max(menuitem.price)
    from menuitem
    where dish_id = dish.id
    group by dish_id
    having max(menuitem.price) != dish.highest_price
), 0) where id in (
    select dish_id
    from dish
    join menuitem on menuitem.dish_id = dish.id
    group by dish_id
    having max(menuitem.price) != dish.highest_price
);

select dish_id, name, dish.highest_price, max(menuitem.price) from dish
join menuitem on menuitem.dish_id = dish.id
group by dish_id, name
having max(menuitem.price) != dish.highest_price;

--- date can't be less than 1850 and greater than 2020
select id, name, event, venue, date
from menu
where date is not null and date != '' and (date < '1850-01-01' or date > '2020-07-01');



----
-- count of the menu ids must match menus appeared
select count(*) from (
    select dish_id
    from MenuItem
    join dish on MenuItem.dish_id = dish.id
    join MenuPage on MenuPage.id = menuitem.menu_page_id
    group by dish_id, name
    having count(menu_id) != dish.menus_appeared
)
-- update 6770 dish items to have times appeared that matches the data to enforce IC
update dish set menus_appeared = coalesce((
    select  count(menu_id)
    from MenuItem
    join MenuPage on MenuPage.id = menuitem.menu_page_id
    where menuitem.dish_id = dish.id
    group by dish_id
    having count(menu_id) != dish.menus_appeared
), 0) where id in (
    select dish_id
    from MenuItem
    join dish on MenuItem.dish_id = dish.id
    join MenuPage on MenuPage.id = menuitem.menu_page_id
    group by dish_id, name
    having count(menu_id) != dish.menus_appeared
);

select dish_id, name, count(menu_id), menus_appeared
from MenuItem
join dish on MenuItem.dish_id = dish.id
join MenuPage on MenuPage.id = menuitem.menu_page_id
group by dish_id, name
having count(menu_id) != dish.menus_appeared;


-- last_appeared cant be before first_appeared
select * from dish where last_appeared < first_appeared;

