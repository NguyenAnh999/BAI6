create database hotelApp;
use hotelApp;
create table Category
(
    id     int primary key auto_increment,
    name   varchar(100) not null unique,
    status tinyint default 1 check (status in (1, 0))
);
create table Room
(
    id          int primary key auto_increment,
    name        varchar(150) not null,
    status      tinyint default 1 check (status in (1, 0)),
    price       float        not null check ( price >= 10000),
    salePrice   float   default 0,
    createdDate date    default (curdate()),
    categoryID  int          not null,
    foreign key (categoryID) references Category (id)
);
CREATE INDEX ten ON Room (name);
CREATE INDEX ngay ON Room (createdDate);
CREATE INDEX gia ON Room (price);
create table Customer
(
    id       int primary key auto_increment,
    name     varchar(150) not null,
    email    varchar(150) not null unique check ( email regexp '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'),
    phone    varchar(50)  not null unique,
    address  varchar(255),
    gender   tinyint      not null check ( gender in (0, 1, 2) ),
    birthDay date         not null
);
create table Booking
(
    id          int primary key auto_increment,
    customerId  int not null,
    foreign key (customerId) references Customer (id),
    bookingDate datetime default (now())
);
alter table booking
    add BStatus tinyint default 1;
create table BookingDetail
(
    bookingID int      not null,
    foreign key (bookingID) references Booking (id),
    roomID    int      not null,
    foreign key (roomID) references Room (id),
    price     float    not null,
    starDate  datetime not null,
    endDate   datetime not null
);

insert into Category (name)
values ('loại 1'),
       ('loại 2'),
       ('loại có 3'),
       ('loại 4'),
       ('loại 5');
insert into Room (name, price, categoryID)
values ('phòng1', 10000, 6),
       ('phòng2', 20000, 6),
       ('phòng3', 30000, 6),
       ('phòng4', 40000, 6),
       ('phòng5', 50000, 6),
       ('phòng6', 60000, 6),
       ('phòng7', 70000, 6),
       ('phòng8', 80000, 6),
       ('phòng9', 90000, 6),
       ('phòng10', 100000, 6),
       ('phòng11', 110000, 6),
       ('phòng12', 120000, 6),
       ('phòng13', 130000, 6),
       ('phòng14', 140000, 6),
       ('phòng15', 150000, 6),
       ('phòng16', 1630000, 6),
       ('phòng17', 170000, 6),
       ('phòng18', 180000, 6);
insert into customer (name, email, phone, address, gender, birthDay)
values ('ánh', 'chjckylovemany@gmail.com', '0942342344', 'ha nam', 1, '1999-05-06'),
       ('sáng', 'chjckylovemany2@gmail.com', '0942342345', 'ha nam', 1, '1997-05-06'),
       ('thuận', 'chjckylovemany3@gmail.com', '0942342346', 'ha nam', 1, '1998-05-06');

insert into booking (customerId, bookingDate)
values (1, now()),
       (2, now()),
       (3, now());

insert into bookingdetail(bookingID, roomID, price, starDate, endDate)
values (1, 1, 400000, now(), '2024-04-29')
     , (1, 2, 600000, now(), '2024-04-29')
     , (2, 3, 700000, now(), '2024-04-29')
     , (2, 4, 800000, now(), '2024-04-29')
     , (3, 5, 900000, now(), '2024-04-29')
     , (3, 6, 1000000, now(), '2024-04-29')
     , (3, 7, 1100000, now(), '2024-04-29');

#Lấy ra danh phòng có sắp xếp giảm dần theo Price gồm các cột sau:
# Id, Name, Price, SalePrice, Status, CategoryName, CreatedDate
select r.Id, r.Name, Price, SalePrice, r.Status, c.name CategoryName, CreatedDate
from room r
         join Category C on C.id = r.categoryID
order by price desc;


#Lấy ra danh sách Category gồm: Id, Name, TotalRoom, Status (Trong đó cột Status nếu = 0, Ẩn, = 1 là Hiển thị )

select c.Id, c.Name, count(r.id), c.Status
from Category c
         join Room R on c.id = R.categoryID
group by c.id;

#Truy vấn danh sách Customer gồm:
# Id, Name, Email, Phone, Address, CreatedDate, Gender, BirthDay, Age (Age là cột suy ra từ BirthDay, Gender nếu = 0 là Nam, 1 là Nữ,2 là khác )
select Id,
       Name,
       Email,
       Phone,
       Address,
       if(gender = 0, 'nam', if(gender = 1, 'nữ', 'khác')) Gender,
       BirthDay,
       year(curdate()) - year(birthDay)                    Age
from customer c;
#Truy vấn xóa các sản phẩm chưa được bán
delete
from Room
where id not in (select b.roomID from bookingdetail b);
#Cập nhật Cột SalePrice tăng thêm 10% cho tất cả các phòng có Price >= 250000
update Room r
set r.salePrice = 10
where r.id in (select roomId.id from (select id from Room where price >= 220000) as roomId);

#View v_getRoomInfo Lấy ra danh sách của 10 phòng có giá cao nhất
create view v_getRoomInfo as
select *
from Room r
order by r.price desc
limit 10;
#View v_getBookingList hiển thị danh sách phiếu đặt hàng gồm:
# Id, BookingDate, Status, CusName, Email, Phone,TotalAmount
# ( Trong đó cột Status nếu = 0 Chưa duyệt, = 1  Đã duyệt, = 2 Đã thanh toán, = 3 Đã hủy )
create view v_getBookingList as
select b.Id, BookingDate, BStatus, c.name, Email, Phone, sum(bd.price) TotalAmount
from booking b
         join BookingDetail BD on b.id = BD.bookingID
         join Customer C on C.id = b.customerId
group by Bd.bookingID;

# Thủ tục addRoomInfo thực hiện thêm mới Room, khi gọi thủ tục truyền
# đầy đủ các giá trị của bảng Room ( Trừ cột tự động tăng )
delimiter //
create procedure addRoomInfo(
    name_in varchar(150),
    price_in float,
    categoryID_in int
)
begin

    insert into Room (name, price, categoryID)
    values (name_in, price_in, categoryID_in);
end //
delimiter ;


# Thủ tục getBookingByCustomerId hiển thị danh sách phieus đặt phòng của khách hàng theo Id  hàng gồm:
# Id, BookingDate, Status, TotalAmount (Trong đó cột Status nếu = 0 Chưa duyệt, = 1  Đã duyệt, = 2 Đã thanh toán, = 3 Đã hủy), Khi gọi thủ tục truyền vào id cảu khách hàng
delimiter //
create procedure getBookingByCustomerId(customer_id_in int)
begin
    select b.Id,
           c.id,
           BookingDate,
           if(bStatus = 1, 'đã duyêt',
              (if(BStatus = 0, 'chưa duyệt', if(BStatus = 2, 'đã thanh toán', 'dã hủy')))) 'status',
           sum(db.price)                                                                   TotalAmount
    from bookingdetail db
             join Booking B on B.id = db.bookingID
             join Customer C on C.id = B.customerId
    where c.id = customer_id_in
    group by db.bookingID;
end //
delimiter ;

call getBookingByCustomerId(1);
# Thủ tục getRoomPaginate lấy ra danh sách phòng có phân trang gồm:
# Id, Name, Price, SalePrice, Khi gọi thủ tuc truyền vào limit và page
delimiter //
create procedure getRoomPaginate(page int)
begin
    select Id, Name, Price, SalePrice
    from Room
    limit page,5;
end //
delimiter ;
call getRoomPaginate(0);
# Tạo trigger tr_Check_Price_Value sao cho khi thêm hoặc sửa phòng Room nếu nếu giá trị của cột
# Price > 5000000 thì tự động chuyển về 5000000 và in ra thông báo ‘Giá phòng lớn nhất 5 triệu’
delimiter //
create trigger tr_Check_Price_Value
    before insert
    on Room
    for each row
begin
    if new.price > 5000000 then set new.price = 5000000; end if;
end //

delimiter //
delimiter //
create trigger tr_Check_Price_Value_update
    before update
    on Room
    for each row
begin
    if new.price > 5000000 then set new.price = 5000000; end if;
end //

delimiter //


# Tạo trigger tr_check_Room_NotAllow khi thực hiện đặt pòng, nếu ngày đến
# (StartDate) và ngày đi (EndDate) của đơn hiện tại mà phòng đã có người đặt rồi thì báo lỗi
# “Phòng này đã có người đặt trong thời gian này, vui lòng chọn thời gian khác”

drop trigger tr_check_Room_NotAllow;
delimiter //
create trigger tr_check_Room_NotAllow
    before insert
    on bookingdetail
    for each row
begin
    if (NEW.starDate >= any (select bd.starDate
                         from bookingdetail bd
                         where new.roomID = bd.roomID)
        and NEW.starDate <= any (select bd.endDate
                             from bookingdetail bd
                             where new.roomID = bd.roomID))
        or (NEW.endDate >= any (select bd.starDate
                            from bookingdetail bd
                            where new.roomID = bd.roomID)
            and NEW.endDate <= any (select bd.endDate
                                from bookingdetail bd
                                where new.roomID = bd.roomID))
    then
        signal sqlstate '45000' set message_text =
                'Phòng này đã có người đặt trong thời gian này, vui lòng chọn thời gian khác';
    end if;
end //
delimiter //
