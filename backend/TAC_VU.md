# TAC VU - PROJECT MANGA BACKEND

Cap nhat: 2026-04-01

## 2. Xac thuc va phan quyen

- [x] Trien khai login bang JWT.
- [x] Trien khai dang ky Reader.
- [x] Cau hinh Authentication/Authorization voi JwtBearer.
- [x] Tao policy phan quyen theo role (AdminOnly, ReaderOnly).
- [x] Hash password truoc khi luu DB.
- [x] Load bien moi truong tu file .env.

Bang chung:

- src/Controllers/AuthController.cs
- src/Services/Implement/AuthService.cs
- src/Configurations/JwtHelper.cs
- src/Configurations/PasswordHelper.cs
- src/Configurations/DotEnvLoader.cs

## 3. Cac module nghiep vu da code

### 3.1 Admin va Reader

- [x] CRUD Admin.
- [x] CRUD Reader.
- [x] Lay thong tin Admin/Reader theo id.

Bang chung:

- src/Controllers/AdminController.cs
- src/Services/Implement/AdminService.cs

### 3.2 Author

- [x] Lay danh sach tac gia.
- [x] Lay tac gia theo id.
- [x] Tao/sua/xoa tac gia.
- [x] Ho tro upload avatar tac gia.

Bang chung:

- src/Controllers/AuthorController.cs
- src/Services/Implement/AuthorService.cs

### 3.3 Genre

- [x] Lay danh sach the loai.
- [x] Tao/sua/xoa the loai.

Bang chung:

- src/Controllers/GenreController.cs
- src/Services/Implement/GenreService.cs

### 3.4 Manga

- [x] Lay danh sach manga.
- [x] Lay manga theo id.
- [x] Tao/sua/xoa manga.
- [x] Ho tro upload thumbnail manga.

Bang chung:

- src/Controllers/MangaController.cs
- src/Services/Implement/MangaService.cs

### 3.5 Chapter va Page

- [x] Quan ly chapter theo manga (lay ds/tao/sua/xoa).
- [x] Quan ly page theo manga + chapter.
- [x] Upload nhieu anh page.
- [x] Xoa page theo danh sach pageIds.

Bang chung:

- src/Controllers/ChapterController.cs
- src/Services/Implement/ChapterService.cs
- src/Controllers/PageController.cs
- src/Services/Implement/PageService.cs

### 3.6 Package va Previlage

- [x] CRUD previlage.
- [x] CRUD package.
- [x] Gan previlage vao package.
- [x] Trien khai mua package cho reader.
- [x] Danh dau reader premium sau khi mua package.

Bang chung:

- src/Controllers/PrevilagesController.cs
- src/Services/Implement/PrevilageService.cs
- src/Controllers/PackageController.cs
- src/Services/Implement/PackageService.cs

### 3.7 Library

- [x] Lay danh sach manga trong thu vien theo Reader dang dang nhap.
- [x] Them manga vao thu vien theo mangaId + readerId.
- [x] Chan them trung manga da ton tai trong thu vien.
- [x] Xoa manga khoi thu vien.
- [x] Tra ve thumbnail manga dang public URL khi lay danh sach thu vien.
- [x] Cau hinh quan he Reader - Library theo 1-nhieu (1 reader co nhieu manga trong thu vien).

Bang chung:

- src/Controllers/LibraryController.cs
- src/Services/Implement/LibraryService.cs
- src/Services/Interface/ILibraryService.cs
- src/Data/ApplicationDbContext.cs
- src/Models/Libraries.cs
- src/Models/Readers.cs

## 4. Luu tru file anh voi MinIO

- [x] Cau hinh MinIO client va option.
- [x] Upload anh len MinIO.
- [x] Tao bucket neu chua ton tai.
- [x] Set policy doc public cho bucket.
- [x] Xoa anh tren MinIO theo object path.
- [x] Tra ve public URL cho anh.

Bang chung:

- src/Configurations/MinioOptions.cs
- src/Services/Implement/MinioStorageService.cs
