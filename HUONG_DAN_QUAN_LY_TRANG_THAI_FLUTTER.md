# HƯỚNG DẪN QUẢN LÝ TRẠNG THÁI TRONG FLUTTER CHI TIẾT

## PHẦN 1: HIỂU VỀ ASYNC/AWAIT VÀ FUTURE

### 1.1 Async/Await cơ bản:
```dart
// Synchronous (đồng bộ) - Code chạy tuần tự
String getUserName() {
  return "Nguyen Van A"; // Trả về ngay lập tức
}

// Asynchronous (bất đồng bộ) - Code chạy không tuần tự
Future<String> getUserNameFromServer() async {
  // Giả lập việc tải dữ liệu từ server (3 giây)
  await Future.delayed(Duration(seconds: 3));
  return "Nguyen Van A"; // Trả về sau 3 giây
}

// Cách sử dụng:
void main() async {
  print("Bắt đầu");
  
  // Cách 1: Sử dụng await
  String name = await getUserNameFromServer();
  print("Tên: $name");
  
  // Cách 2: Sử dụng .then()
  getUserNameFromServer().then((name) {
    print("Tên: $name");
  });
  
  print("Kết thúc");
}
```

### 1.2 Tại sao cần Async/Await?
```dart
// VÍ DỤ: Tải danh sách bài viết từ Firebase
class PostService {
  // ❌ CÁCH SAI - Blocking UI
  static List<Post> getPostsSync() {
    // Giả sử đây là API call mất 5 giây
    // UI sẽ bị đóng băng 5 giây!
    return [];
  }
  
  // ✅ CÁCH ĐÚNG - Non-blocking UI
  static Future<List<Post>> getPostsAsync() async {
    try {
      // UI vẫn hoạt động bình thường trong lúc chờ
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      return snapshot.docs.map((doc) => 
        Post.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      print('Lỗi: $e');
      return [];
    }
  }
}
```

### 1.3 Các trạng thái của Future:
```dart
enum FutureState {
  waiting,    // Đang chờ (pending)
  completed,  // Hoàn thành thành công
  error,      // Lỗi
}

// Ví dụ xử lý các trạng thái:
Future<void> handleFutureStates() async {
  print("Trạng thái: Waiting"); // Bắt đầu
  
  try {
    String result = await someAsyncOperation();
    print("Trạng thái: Completed - Kết quả: $result");
  } catch (e) {
    print("Trạng thái: Error - Lỗi: $e"); 
  }
}
```

## PHẦN 2: FUTUREBUILDER - QUẢN LÝ TRẠNG THÁI ASYNC TRONG UI

### 2.1 Cấu trúc FutureBuilder cơ bản:
```dart
class UserProfileScreen extends StatelessWidget {
  final String userId;
  
  UserProfileScreen({required this.userId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        // Future cần theo dõi
        future: getUserData(userId),
        
        // Hàm builder được gọi khi Future thay đổi trạng thái
        builder: (context, snapshot) {
          // TRẠNG THÁI 1: Đang loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu...'),
                ],
              ),
            );
          }
          
          // TRẠNG THÁI 2: Có lỗi
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () {
                      // Refresh page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: userId),
                        ),
                      );
                    },
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          
          // TRẠNG THÁI 3: Không có dữ liệu
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, color: Colors.grey, size: 64),
                  SizedBox(height: 16),
                  Text('Không tìm thấy người dùng'),
                ],
              ),
            );
          }
          
          // TRẠNG THÁI 4: Có dữ liệu - Hiển thị UI
          Map<String, dynamic> userData = snapshot.data!;
          
          return Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userData['photoURL'] ?? ''),
              ),
              SizedBox(height: 16),
              Text(
                userData['displayName'] ?? 'Không có tên',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(userData['email'] ?? ''),
              Text('Followers: ${userData['followers'] ?? 0}'),
              Text('Following: ${userData['following'] ?? 0}'),
            ],
          );
        },
      ),
    );
  }
  
  // Hàm async để lấy dữ liệu user
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Không thể tải dữ liệu user: $e');
    }
  }
}
```

### 2.2 FutureBuilder với refresh functionality:
```dart
class PostListScreen extends StatefulWidget {
  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late Future<List<Post>> _postsFuture;
  
  @override
  void initState() {
    super.initState();
    _postsFuture = loadPosts(); // Khởi tạo Future
  }
  
  // Hàm refresh - tạo Future mới
  Future<void> refreshPosts() async {
    setState(() {
      _postsFuture = loadPosts(); // Tạo Future mới để trigger rebuild
    });
  }
  
  Future<List<Post>> loadPosts() async {
    // Simulate loading time
    await Future.delayed(Duration(seconds: 2));
    
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    
    return snapshot.docs.map((doc) => 
      Post.fromMap(doc.data() as Map<String, dynamic>)
    ).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách bài viết'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshPosts, // Refresh button
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshPosts, // Pull to refresh
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: refreshPosts,
                      child: Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Không có bài viết nào'));
            }
            
            List<Post> posts = snapshot.data!;
            
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                Post post = posts[index];
                return PostWidget(post: post);
              },
            );
          },
        ),
      ),
    );
  }
}
```

## PHẦN 3: STREAMBUILDER - REALTIME STATE MANAGEMENT

### 3.1 Stream vs Future:
```dart
// Future: Chỉ trả về 1 giá trị duy nhất
Future<String> getOneName() async {
  await Future.delayed(Duration(seconds: 1));
  return "Tên duy nhất";
}

// Stream: Có thể trả về nhiều giá trị theo thời gian
Stream<String> getMultipleNames() async* {
  await Future.delayed(Duration(seconds: 1));
  yield "Tên 1";
  
  await Future.delayed(Duration(seconds: 1));
  yield "Tên 2";
  
  await Future.delayed(Duration(seconds: 1));
  yield "Tên 3";
}
```

### 3.2 StreamBuilder cơ bản:
```dart
class RealTimePostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Posts Real-time')),
      body: StreamBuilder<QuerySnapshot>(
        // Stream từ Firestore - tự động cập nhật khi có thay đổi
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        
        builder: (context, snapshot) {
          // Trạng thái chờ dữ liệu đầu tiên
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          // Có lỗi
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          
          // Không có dữ liệu
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Chưa có bài viết nào'));
          }
          
          // Có dữ liệu - hiển thị danh sách
          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> postData = docs[index].data() as Map<String, dynamic>;
              
              return Card(
                child: ListTile(
                  title: Text(postData['content'] ?? ''),
                  subtitle: Text('Likes: ${postData['likes'] ?? 0}'),
                  trailing: Text(
                    formatTimeAgo(postData['createdAt']?.toDate()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    Duration difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
```

### 3.3 Kết hợp StreamBuilder với User Authentication:
```dart
class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        // Lắng nghe thay đổi trạng thái authentication
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Đang kiểm tra trạng thái auth
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          
          // Đã đăng nhập
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(user: snapshot.data!);
          }
          
          // Chưa đăng nhập
          return LoginScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang kiểm tra đăng nhập...'),
          ],
        ),
      ),
    );
  }
}
```

## PHẦN 4: SETSTATE - LOCAL STATE MANAGEMENT

### 4.1 setState cơ bản:
```dart
class CounterScreen extends StatefulWidget {
  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;        // State variable
  bool _isLoading = false; // Loading state
  String _message = '';    // Message state
  
  // Hàm thay đổi state
  void _incrementCounter() {
    setState(() {
      _counter++; // Thay đổi state và trigger rebuild
    });
  }
  
  // Async operation với loading state
  Future<void> _saveCounter() async {
    setState(() {
      _isLoading = true; // Bắt đầu loading
      _message = '';
    });
    
    try {
      // Giả lập save to server
      await Future.delayed(Duration(seconds: 2));
      
      setState(() {
        _isLoading = false; // Kết thúc loading
        _message = 'Đã lưu thành công!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Lỗi: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter với setState')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Số đếm:',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '$_counter',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Hiển thị message
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('Lỗi') ? Colors.red : Colors.green,
                ),
              ),
            
            SizedBox(height: 20),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _incrementCounter,
                  child: Text('Tăng'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveCounter, // Disable khi loading
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Lưu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.2 setState với Form validation:
```dart
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _emailError = '';
  String _passwordError = '';
  String _generalError = '';
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Validate email realtime
  void _validateEmail(String email) {
    setState(() {
      if (email.isEmpty) {
        _emailError = 'Email không được để trống';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Email không hợp lệ';
      } else {
        _emailError = '';
      }
    });
  }
  
  // Validate password realtime
  void _validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordError = 'Mật khẩu không được để trống';
      } else if (password.length < 6) {
        _passwordError = 'Mật khẩu phải có ít nhất 6 ký tự';
      } else {
        _passwordError = '';
      }
    });
  }
  
  // Submit form
  Future<void> _submitForm() async {
    // Validate tất cả fields
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);
    
    // Nếu có lỗi validation, không submit
    if (_emailError.isNotEmpty || _passwordError.isNotEmpty) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _generalError = '';
    });
    
    try {
      // Thực hiện login
      UserCredential? userCredential = await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (userCredential != null) {
        // Login thành công - chuyển màn hình
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        setState(() {
          _generalError = 'Đăng nhập thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _generalError = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng nhập')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Email field
            TextField(
              controller: _emailController,
              onChanged: _validateEmail,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _emailError.isEmpty ? null : _emailError,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // Password field
            TextField(
              controller: _passwordController,
              onChanged: _validatePassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                errorText: _passwordError.isEmpty ? null : _passwordError,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // General error message
            if (_generalError.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _generalError,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            
            SizedBox(height: 16),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Đăng nhập'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## PHẦN 5: PROVIDER PATTERN - GLOBAL STATE MANAGEMENT

### 5.1 Cài đặt Provider:
```yaml
# pubspec.yaml
dependencies:
  provider: ^6.0.5
```

### 5.2 Tạo Provider class:
```dart
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String _error = '';
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isLoggedIn => _currentUser != null;
  
  // Đăng nhập
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      UserCredential? userCredential = await AuthService.signIn(
        email: email,
        password: password,
      );
      
      if (userCredential != null) {
        await _loadUserData(userCredential.user!.uid);
        return true;
      } else {
        _setError('Đăng nhập thất bại');
        return false;
      }
    } catch (e) {
      _setError('Lỗi đăng nhập: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Đăng xuất
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    notifyListeners(); // Thông báo UI cập nhật
  }
  
  // Cập nhật profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    
    try {
      bool success = await UserService.updateProfile(_currentUser!.id, updates);
      
      if (success) {
        // Cập nhật local state
        _currentUser = _currentUser!.copyWith(updates);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Lỗi cập nhật profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = '';
    notifyListeners();
  }
  
  Future<void> _loadUserData(String userId) async {
    UserModel? user = await UserService.getUserById(userId);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }
}
```

### 5.3 Sử dụng Provider trong app:
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PostProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoggedIn) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}

// Sử dụng Provider trong widget
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (userProvider.error.isNotEmpty) {
            return Center(child: Text('Lỗi: ${userProvider.error}'));
          }
          
          UserModel? user = userProvider.currentUser;
          if (user == null) {
            return Center(child: Text('Chưa đăng nhập'));
          }
          
          return Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user.photoURL),
              ),
              Text(user.displayName),
              Text(user.email),
              ElevatedButton(
                onPressed: () => userProvider.logout(),
                child: Text('Đăng xuất'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

## PHẦN 6: BLOC PATTERN - ADVANCED STATE MANAGEMENT

### 6.1 Cài đặt flutter_bloc:
```yaml
# pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.3
```

### 6.2 Tạo Bloc cho Posts:
```dart
// Events
abstract class PostEvent {}

class LoadPosts extends PostEvent {}
class RefreshPosts extends PostEvent {}
class CreatePost extends PostEvent {
  final String content;
  final List<String> imageUrls;
  
  CreatePost({required this.content, required this.imageUrls});
}

// States
abstract class PostState {}

class PostInitial extends PostState {}
class PostLoading extends PostState {}
class PostLoaded extends PostState {
  final List<PostModel> posts;
  
  PostLoaded({required this.posts});
}
class PostError extends PostState {
  final String message;
  
  PostError({required this.message});
}

// Bloc
class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc() : super(PostInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<RefreshPosts>(_onRefreshPosts);
    on<CreatePost>(_onCreatePost);
  }
  
  Future<void> _onLoadPosts(LoadPosts event, Emitter<PostState> emit) async {
    emit(PostLoading());
    
    try {
      List<PostModel> posts = await PostService.getAllPosts();
      emit(PostLoaded(posts: posts));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }
  
  Future<void> _onRefreshPosts(RefreshPosts event, Emitter<PostState> emit) async {
    try {
      List<PostModel> posts = await PostService.getAllPosts();
      emit(PostLoaded(posts: posts));
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }
  
  Future<void> _onCreatePost(CreatePost event, Emitter<PostState> emit) async {
    try {
      await PostService.createPost(PostModel(
        authorId: FirebaseAuth.instance.currentUser!.uid,
        content: event.content,
        imageUrls: event.imageUrls,
      ));
      
      // Reload posts sau khi tạo
      add(LoadPosts());
    } catch (e) {
      emit(PostError(message: e.toString()));
    }
  }
}
```

### 6.3 Sử dụng Bloc trong UI:
```dart
class PostListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PostBloc()..add(LoadPosts()),
      child: Scaffold(
        appBar: AppBar(title: Text('Posts')),
        body: BlocBuilder<PostBloc, PostState>(
          builder: (context, state) {
            if (state is PostLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (state is PostError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi: ${state.message}'),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PostBloc>().add(LoadPosts());
                      },
                      child: Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is PostLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PostBloc>().add(RefreshPosts());
                },
                child: ListView.builder(
                  itemCount: state.posts.length,
                  itemBuilder: (context, index) {
                    return PostWidget(post: state.posts[index]);
                  },
                ),
              );
            }
            
            return Center(child: Text('Chưa có dữ liệu'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePostScreen(),
              ),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## PHẦN 7: BEST PRACTICES VÀ PERFORMANCE

### 7.1 Tối ưu hiệu suất:
```dart
// ❌ KHÔNG NÊN: Tạo Future trong build method
class BadExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // ❌ Future được tạo mới mỗi lần rebuild!
      future: expensiveOperation(),
      builder: (context, snapshot) {
        return Text('Data');
      },
    );
  }
}

// ✅ NÊN: Tạo Future một lần
class GoodExample extends StatefulWidget {
  @override
  _GoodExampleState createState() => _GoodExampleState();
}

class _GoodExampleState extends State<GoodExample> {
  late Future<String> _dataFuture;
  
  @override
  void initState() {
    super.initState();
    _dataFuture = expensiveOperation(); // Tạo một lần duy nhất
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _dataFuture, // Sử dụng Future đã tạo
      builder: (context, snapshot) {
        return Text(snapshot.data ?? 'Loading...');
      },
    );
  }
}
```

### 7.2 Memory management:
```dart
class ProperResourceManagement extends StatefulWidget {
  @override
  _ProperResourceManagementState createState() => _ProperResourceManagementState();
}

class _ProperResourceManagementState extends State<ProperResourceManagement> {
  StreamSubscription? _subscription;
  Timer? _timer;
  TextEditingController? _controller;
  
  @override
  void initState() {
    super.initState();
    
    // Khởi tạo resources
    _controller = TextEditingController();
    
    // Stream subscription
    _subscription = FirebaseFirestore.instance
        .collection('posts')
        .snapshots()
        .listen((snapshot) {
      // Handle data
    });
    
    // Timer
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      // Periodic task
    });
  }
  
  @override
  void dispose() {
    // ❗ QUAN TRỌNG: Cleanup resources
    _subscription?.cancel();
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextField(controller: _controller),
    );
  }
}
```

### 7.3 Error handling patterns:
```dart
class RobustStateManagement extends StatefulWidget {
  @override
  _RobustStateManagementState createState() => _RobustStateManagementState();
}

class _RobustStateManagementState extends State<RobustStateManagement> {
  bool _isLoading = false;
  String? _error;
  List<PostModel> _posts = [];
  
  Future<void> _loadPosts() async {
    if (!mounted) return; // Kiểm tra widget còn tồn tại
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      List<PostModel> posts = await PostService.getAllPosts();
      
      if (mounted) { // Kiểm tra lại trước khi setState
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: $_error'),
            ElevatedButton(
              onPressed: _loadPosts,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return PostWidget(post: _posts[index]);
      },
    );
  }
}
```

---

**KẾT LUẬN**:

Quản lý trạng thái trong Flutter có nhiều cấp độ:

1. **setState**: Cho local state đơn giản
2. **FutureBuilder/StreamBuilder**: Cho async operations và realtime data
3. **Provider**: Cho global state management
4. **Bloc**: Cho complex state logic và separation of concerns

Chọn phương pháp phù hợp với độ phức tạp của app:
- App đơn giản: setState + FutureBuilder/StreamBuilder
- App trung bình: Provider
- App phức tạp: Bloc/Cubit

Luôn nhớ cleanup resources và handle errors properly để tránh memory leaks và crashes!
