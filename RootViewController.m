#import "RootViewController.h"
#import <spawn.h>

extern char **environ;

#define kCyanColor [UIColor colorWithRed:0.0 green:0.75 blue:0.85 alpha:1.0]

typedef NS_ENUM(NSInteger, InstallMethod) {
    InstallMethodDpkg,    // Download .deb then dpkg -i
    InstallMethodFileCopy // Copy bundled files to system paths
};

// ============================================================================
// MARK: - LibraryInfo Model
// ============================================================================

@interface LibraryInfo : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, strong) NSArray<NSString *> *versions;
@property (nonatomic, assign) NSInteger selectedVersionIndex;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *downloadURLs;
@property (nonatomic, copy) NSString *packageID; // For DPKG uninstallation
@property (nonatomic, assign) BOOL isDaemon; // If true, supports start/stop service
@property (nonatomic, assign) InstallMethod installMethod;
@property (nonatomic, strong) NSArray<NSDictionary *> *filesToCopy; // for FileCopy: @{@"src": bundlePath, @"dst": systemPath}
@property (nonatomic, assign) BOOL isInstalled;
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) float downloadProgress;
@end

@implementation LibraryInfo
@end

// ============================================================================
// MARK: - LibraryCell
// ============================================================================

@interface LibraryCell : UITableViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UILabel *methodLabel;
@property (nonatomic, strong) UIButton *installButton;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UIView *cardView;
@end

@implementation LibraryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        // Card container
        self.cardView = [[UIView alloc] init];
        self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cardView.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        self.cardView.layer.cornerRadius = 16;
        self.cardView.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1.0].CGColor;
        self.cardView.layer.borderWidth = 1;
        [self.contentView addSubview:self.cardView];
        
        // Icon
        self.iconView = [[UIImageView alloc] init];
        self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
        self.iconView.tintColor = kCyanColor;
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self.cardView addSubview:self.iconView];
        
        // Name
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.nameLabel.font = [UIFont boldSystemFontOfSize:20];
        self.nameLabel.textColor = [UIColor whiteColor];
        [self.cardView addSubview:self.nameLabel];
        
        // Description
        self.descLabel = [[UILabel alloc] init];
        self.descLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.descLabel.font = [UIFont systemFontOfSize:13];
        self.descLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        self.descLabel.numberOfLines = 2;
        [self.cardView addSubview:self.descLabel];
        
        // Version label (tappable)
        self.versionLabel = [[UILabel alloc] init];
        self.versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.versionLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightMedium];
        self.versionLabel.textColor = kCyanColor;
        self.versionLabel.textAlignment = NSTextAlignmentRight;
        [self.cardView addSubview:self.versionLabel];
        
        // Method badge
        self.methodLabel = [[UILabel alloc] init];
        self.methodLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.methodLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
        self.methodLabel.textColor = [UIColor whiteColor];
        self.methodLabel.textAlignment = NSTextAlignmentCenter;
        self.methodLabel.layer.cornerRadius = 6;
        self.methodLabel.clipsToBounds = YES;
        [self.cardView addSubview:self.methodLabel];
        
        // Install button
        self.installButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.installButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.installButton setTitle:@"Install" forState:UIControlStateNormal];
        [self.installButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.installButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        self.installButton.backgroundColor = [UIColor systemBlueColor];
        self.installButton.layer.cornerRadius = 10;
        [self.cardView addSubview:self.installButton];
        
        // Progress bar
        self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
        self.progressBar.progressTintColor = kCyanColor;
        self.progressBar.trackTintColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.progressBar.hidden = YES;
        self.progressBar.layer.cornerRadius = 2;
        self.progressBar.clipsToBounds = YES;
        [self.cardView addSubview:self.progressBar];
        
        // Constraints
        [NSLayoutConstraint activateConstraints:@[
            // Card
            [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [self.cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],
            [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            
            // Icon
            [self.iconView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
            [self.iconView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:16],
            [self.iconView.widthAnchor constraintEqualToConstant:36],
            [self.iconView.heightAnchor constraintEqualToConstant:36],
            
            // Name
            [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:12],
            [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.iconView.centerYAnchor constant:-8],
            
            // Method badge (next to name)
            [self.methodLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor constant:8],
            [self.methodLabel.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
            [self.methodLabel.widthAnchor constraintGreaterThanOrEqualToConstant:50],
            [self.methodLabel.heightAnchor constraintEqualToConstant:18],
            
            // Version
            [self.versionLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
            [self.versionLabel.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
            [self.versionLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.methodLabel.trailingAnchor constant:4],
            
            // Desc
            [self.descLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:12],
            [self.descLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
            [self.descLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:4],
            
            // Install button
            [self.installButton.topAnchor constraintEqualToAnchor:self.descLabel.bottomAnchor constant:14],
            [self.installButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
            [self.installButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
            [self.installButton.heightAnchor constraintEqualToConstant:42],
            
            // Progress
            [self.progressBar.topAnchor constraintEqualToAnchor:self.installButton.bottomAnchor constant:10],
            [self.progressBar.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16],
            [self.progressBar.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-16],
            [self.progressBar.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-16],
            [self.progressBar.heightAnchor constraintEqualToConstant:4],
        ]];
    }
    return self;
}

@end

// ============================================================================
// MARK: - RootViewController
// ============================================================================

@interface RootViewController () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *respringButton;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) NSMutableArray<LibraryInfo *> *libraries;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *activeDownloads;
@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, copy) NSString *sudoPassword;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = @"Tweak Installer";
    
    // Dark navigation bar style
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.activeDownloads = [NSMutableDictionary dictionary];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.downloadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    [self setupLibraries];
    [self setupUI];
}

// ============================================================================
// MARK: - Library Data
// ============================================================================

- (void)setupLibraries {
    self.libraries = [NSMutableArray array];
    
    // --- Frida (Download .deb + dpkg install) ---
    LibraryInfo *frida = [[LibraryInfo alloc] init];
    frida.name = @"Frida";
    frida.desc = @"Dynamic instrumentation toolkit for reverse engineering, debugging, and live code injection.";
    frida.icon = @"ant.fill";
    frida.installMethod = InstallMethodDpkg;
    frida.versions = @[@"Fetching..."];
    frida.selectedVersionIndex = 0;
    frida.downloadURLs = @{};
    frida.packageID = @"re.frida.server";
    frida.isDaemon = YES;
    [self.libraries addObject:frida];
    [self fetchFridaReleasesForLibrary:frida atIndex:(self.libraries.count - 1)];
    
    // --- Dobby (Bundled file copy) ---
    LibraryInfo *dobby = [[LibraryInfo alloc] init];
    dobby.name = @"Dobby";
    dobby.desc = @"Lightweight multi-platform inline hook framework for ARM64. Essential for IL2CPP game modding.";
    dobby.icon = @"hammer.fill";
    dobby.installMethod = InstallMethodFileCopy;
    dobby.versions = @[@"latest"];
    dobby.selectedVersionIndex = 0;
    
    NSString *dobbyBundle = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dobby"];
    dobby.filesToCopy = @[
        // System paths
        @{@"src": [dobbyBundle stringByAppendingPathComponent:@"libdobby.dylib"],
          @"dst": @"/var/jb/usr/lib/libdobby.dylib"},
        @{@"src": [dobbyBundle stringByAppendingPathComponent:@"libdobby.a"],
          @"dst": @"/var/jb/usr/lib/libdobby.a"},
        @{@"src": [dobbyBundle stringByAppendingPathComponent:@"dobby.h"],
          @"dst": @"/var/jb/usr/include/dobby.h"},
        // Theos paths for development (to fit dobby use.md)
        @{@"src": [dobbyBundle stringByAppendingPathComponent:@"libdobby.a"],
          @"dst": @"/var/jb/opt/theos/lib/libdobby.a"},
        @{@"src": [dobbyBundle stringByAppendingPathComponent:@"dobby.h"],
          @"dst": @"/var/jb/opt/theos/include/dobby.h"},
    ];
    [self.libraries addObject:dobby];
    
    [self checkInstalledStatus];
}

- (void)checkInstalledStatus {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSInteger i = 0; i < self.libraries.count; i++) {
            LibraryInfo *lib = self.libraries[i];
            BOOL installed = NO;
            
            if (lib.installMethod == InstallMethodDpkg && lib.packageID.length > 0) {
                NSString *res = [self runCommand:@"/var/jb/usr/bin/dpkg-query" args:@[@"-W", @"-f=${Status}", lib.packageID]];
                if ([res containsString:@"install ok installed"]) {
                    installed = YES;
                }
            } else if (lib.installMethod == InstallMethodFileCopy && lib.filesToCopy.count > 0) {
                NSString *firstFile = lib.filesToCopy.firstObject[@"dst"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:firstFile]) {
                    installed = YES;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                lib.isInstalled = installed;
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
        }
    });
}

- (void)fetchFridaReleasesForLibrary:(LibraryInfo *)frida atIndex:(NSInteger)idx {
    NSURL *url = [NSURL URLWithString:@"https://api.github.com/repos/frida/frida/releases"];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                frida.versions = @[@"Error"];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
            return;
        }
        
        NSError *jsonError;
        NSArray *releases = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (!jsonError && [releases isKindOfClass:[NSArray class]]) {
            NSMutableArray *fetchedVersions = [NSMutableArray array];
            NSMutableDictionary *fetchedURLs = [NSMutableDictionary dictionary];
            
            for (NSDictionary *release in releases) {
                NSString *tagName = release[@"tag_name"];
                NSArray *assets = release[@"assets"];
                if (tagName && [assets isKindOfClass:[NSArray class]]) {
                    // Check if it has iphoneos-arm64.deb
                    NSString *expectedName = [NSString stringWithFormat:@"frida_%@_iphoneos-arm64.deb", tagName];
                    for (NSDictionary *asset in assets) {
                        NSString *assetName = asset[@"name"];
                        if ([assetName isEqualToString:expectedName]) {
                            NSString *downloadURL = asset[@"browser_download_url"];
                            if (downloadURL) {
                                [fetchedVersions addObject:tagName];
                                fetchedURLs[tagName] = downloadURL;
                            }
                            break;
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (fetchedVersions.count > 0) {
                    frida.versions = fetchedVersions;
                    frida.downloadURLs = fetchedURLs;
                    frida.selectedVersionIndex = 0;
                } else {
                    frida.versions = @[@"None found"];
                }
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
        }
    }];
    [task resume];
}

// ============================================================================
// MARK: - UI Setup
// ============================================================================

- (void)setupUI {
    // Table view
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[LibraryCell class] forCellReuseIdentifier:@"LibraryCell"];
    [self.view addSubview:self.tableView];
    
    // Respring button
    self.respringButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.respringButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.respringButton setTitle:@"  Respring Device" forState:UIControlStateNormal];
    [self.respringButton setImage:[UIImage systemImageNamed:@"arrow.counterclockwise.circle.fill"] forState:UIControlStateNormal];
    [self.respringButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.respringButton.tintColor = [UIColor whiteColor];
    self.respringButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.respringButton.backgroundColor = [UIColor systemRedColor];
    self.respringButton.layer.cornerRadius = 14;
    [self.respringButton addTarget:self action:@selector(respringTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.respringButton];
    
    // Log text view
    self.logTextView = [[UITextView alloc] init];
    self.logTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logTextView.editable = NO;
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
    self.logTextView.layer.cornerRadius = 12;
    self.logTextView.layer.borderColor = [UIColor colorWithWhite:0.18 alpha:1.0].CGColor;
    self.logTextView.layer.borderWidth = 1;
    self.logTextView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    self.logTextView.textColor = [UIColor systemGreenColor];
    self.logTextView.text = @"[*] Ready. Select a library and tap Install.\n";
    [self.view addSubview:self.logTextView];
    
    // Constraints
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.tableView.heightAnchor constraintEqualToConstant:350],
        
        [self.respringButton.topAnchor constraintEqualToAnchor:self.tableView.bottomAnchor constant:8],
        [self.respringButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.respringButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.respringButton.heightAnchor constraintEqualToConstant:50],
        
        [self.logTextView.topAnchor constraintEqualToAnchor:self.respringButton.bottomAnchor constant:10],
        [self.logTextView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.logTextView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.logTextView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-10],
    ]];
}

// ============================================================================
// MARK: - UITableView
// ============================================================================

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.libraries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 165;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LibraryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LibraryCell" forIndexPath:indexPath];
    LibraryInfo *lib = self.libraries[indexPath.row];
    
    cell.nameLabel.text = lib.name;
    cell.descLabel.text = lib.desc;
    cell.iconView.image = [UIImage systemImageNamed:lib.icon];
    
    NSString *version = lib.versions[lib.selectedVersionIndex];
    cell.versionLabel.text = [NSString stringWithFormat:@"v%@  ▼", version];
    
    // Color the icon per library
    NSArray *colors = @[kCyanColor, [UIColor systemOrangeColor]];
    cell.iconView.tintColor = colors[indexPath.row % colors.count];
    
    // Method badge
    if (lib.installMethod == InstallMethodDpkg) {
        cell.methodLabel.text = @" DPKG ";
        cell.methodLabel.backgroundColor = [UIColor colorWithRed:0.3 green:0.5 blue:0.9 alpha:1.0];
    } else {
        cell.methodLabel.text = @" BUNDLED ";
        cell.methodLabel.backgroundColor = [UIColor colorWithRed:0.8 green:0.5 blue:0.2 alpha:1.0];
    }
    
    if (lib.isDownloading) {
        [cell.installButton setTitle:@"Downloading..." forState:UIControlStateNormal];
        cell.installButton.backgroundColor = [UIColor systemGrayColor];
        cell.installButton.enabled = NO;
        cell.progressBar.hidden = NO;
        cell.progressBar.progress = lib.downloadProgress;
    } else if (lib.isInstalled) {
        [cell.installButton setTitle:@"✓ Installed (Tap options)" forState:UIControlStateNormal];
        cell.installButton.backgroundColor = [UIColor systemGreenColor];
        cell.installButton.enabled = YES;
        cell.progressBar.hidden = YES;
    } else {
        cell.progressBar.hidden = YES;
        NSString *btnTitle = (lib.installMethod == InstallMethodDpkg) ? @"Install (DPKG)" : @"Install (Files)";
        [cell.installButton setTitle:btnTitle forState:UIControlStateNormal];
        
        if (lib.installMethod == InstallMethodDpkg && lib.downloadURLs.count == 0) {
            cell.installButton.backgroundColor = [UIColor systemGrayColor];
            cell.installButton.enabled = NO;
        } else {
            cell.installButton.backgroundColor = [UIColor systemBlueColor];
            cell.installButton.enabled = YES;
        }
    }
    
    // Remove old targets
    [cell.installButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    cell.installButton.tag = indexPath.row;
    [cell.installButton addTarget:self action:@selector(manageLibrary:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add tap gesture on version label to pick version
    cell.versionLabel.userInteractionEnabled = YES;
    for (UIGestureRecognizer *g in cell.versionLabel.gestureRecognizers) {
        [cell.versionLabel removeGestureRecognizer:g];
    }
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectVersion:)];
    cell.versionLabel.tag = indexPath.row;
    [cell.versionLabel addGestureRecognizer:tap];
    
    return cell;
}

// ============================================================================
// MARK: - Version Selection
// ============================================================================

- (void)selectVersion:(UITapGestureRecognizer *)gesture {
    NSInteger idx = gesture.view.tag;
    LibraryInfo *lib = self.libraries[idx];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Select %@ Version", lib.name]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSInteger i = 0; i < lib.versions.count; i++) {
        NSString *version = lib.versions[i];
        NSString *title = (i == lib.selectedVersionIndex) ? [NSString stringWithFormat:@"✓ %@", version] : version;
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            lib.selectedVersionIndex = i;
            lib.isInstalled = NO;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }];
        [alert addAction:action];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

// ============================================================================
// MARK: - Install / Manage Dispatcher
// ============================================================================

- (void)ensurePasswordAndExecute:(void(^)(void))block {
    if (self.sudoPassword.length > 0) {
        block();
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Authentication"
                                                                   message:@"Please enter your 'mobile' user password to authorize system changes (default is usually 'alpine')."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Password";
        textField.secureTextEntry = YES;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *pwd = alert.textFields.firstObject.text;
        if (pwd.length > 0) {
            self.sudoPassword = pwd;
            block();
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)manageLibrary:(UIButton *)sender {
    NSInteger idx = sender.tag;
    LibraryInfo *lib = self.libraries[idx];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Manage %@", lib.name]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Install / Reinstall" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self ensurePasswordAndExecute:^{
            [self performInstallForLibrary:lib atIndex:idx];
        }];
    }]];
    
    if (lib.isDaemon && lib.packageID.length > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Start Service" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self ensurePasswordAndExecute:^{
                [self performDaemonAction:@"load" forLibrary:lib];
            }];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Stop Service" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self ensurePasswordAndExecute:^{
                [self performDaemonAction:@"unload" forLibrary:lib];
            }];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Uninstall" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self ensurePasswordAndExecute:^{
            [self performUninstallForLibrary:lib atIndex:idx];
        }];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
         alert.popoverPresentationController.sourceView = sender;
         alert.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performInstallForLibrary:(LibraryInfo *)lib atIndex:(NSInteger)idx {
    if (lib.installMethod == InstallMethodDpkg) {
        [self installViaDpkg:lib atIndex:idx];
    } else {
        [self installViaFileCopy:lib atIndex:idx];
    }
}

- (void)performUninstallForLibrary:(LibraryInfo *)lib atIndex:(NSInteger)idx {
    [self appendLog:[NSString stringWithFormat:@"\n[*] Uninstalling %@ ...", lib.name]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (lib.installMethod == InstallMethodDpkg) {
            if (lib.packageID.length > 0) {
                [self runSudoCommand:@"dpkg" args:@[@"-r", lib.packageID]];
            } else {
                [self appendLog:[NSString stringWithFormat:@"[!] No packageID defined for %@", lib.name]];
            }
        } else if (lib.installMethod == InstallMethodFileCopy) {
            for (NSDictionary *entry in lib.filesToCopy) {
                NSString *dst = entry[@"dst"];
                [self appendLog:[NSString stringWithFormat:@"[*] Removing %@", [dst lastPathComponent]]];
                [self runSudoCommand:@"rm" args:@[@"-f", dst]];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            lib.isInstalled = NO;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [self appendLog:[NSString stringWithFormat:@"[✓] %@ uninstalled successfully!", lib.name]];
        });
    });
}

- (void)performDaemonAction:(NSString *)action forLibrary:(LibraryInfo *)lib {
    [self appendLog:[NSString stringWithFormat:@"\n[*] Executing '%@' for %@ daemon...", action, lib.name]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *plistPath = [NSString stringWithFormat:@"/var/jb/Library/LaunchDaemons/%@.plist", lib.packageID];
        
        // For 'load', we might also need to unload first, but standard load -w works.
        [self runSudoCommand:@"launchctl" args:@[action, @"-w", plistPath]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self appendLog:[NSString stringWithFormat:@"[✓] %@ daemon %@ed.", lib.name, action]];
        });
    });
}

// ============================================================================
// MARK: - Install via dpkg (Frida)
// ============================================================================

- (void)installViaDpkg:(LibraryInfo *)lib atIndex:(NSInteger)idx {
    NSString *version = lib.versions[lib.selectedVersionIndex];
    NSString *urlStr = lib.downloadURLs[version];
    
    if (!urlStr) {
        [self appendLog:[NSString stringWithFormat:@"[!] No download URL for %@ v%@", lib.name, version]];
        return;
    }
    
    [self appendLog:[NSString stringWithFormat:@"\n[*] Downloading %@ v%@ ...", lib.name, version]];
    
    lib.isDownloading = YES;
    lib.downloadProgress = 0.0;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSessionDownloadTask *task = [self.downloadSession downloadTaskWithURL:url];
    self.activeDownloads[@(task.taskIdentifier).stringValue] = @(idx);
    [task resume];
}

// ============================================================================
// MARK: - Install via File Copy (Dobby)
// ============================================================================

- (void)installViaFileCopy:(LibraryInfo *)lib atIndex:(NSInteger)idx {
    [self appendLog:[NSString stringWithFormat:@"\n[*] Installing %@ (bundled) ...", lib.name]];
    
    lib.isDownloading = YES;
    lib.downloadProgress = 0.0;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL allSuccess = YES;
        NSFileManager *fm = [NSFileManager defaultManager];
        
        for (NSUInteger i = 0; i < lib.filesToCopy.count; i++) {
            NSDictionary *entry = lib.filesToCopy[i];
            NSString *src = entry[@"src"];
            NSString *dst = entry[@"dst"];
            
            // Ensure destination directory exists
            NSString *dstDir = [dst stringByDeletingLastPathComponent];
            
            // Use sudo for root privileges on Dopamine rootless
            [self appendLog:[NSString stringWithFormat:@"[*] sudo mkdir -p %@", dstDir]];
            [self runSudoCommand:@"mkdir" args:@[@"-p", dstDir]];
            
            [self appendLog:[NSString stringWithFormat:@"[*] Copying %@ -> %@", [src lastPathComponent], dst]];
            
            // Remove existing file first
            if ([fm fileExistsAtPath:dst]) {
                [self runSudoCommand:@"rm" args:@[@"-f", dst]];
            }
            
            [self runSudoCommand:@"cp" args:@[src, dst]];
            
            // Verify copy succeeded
            if ([fm fileExistsAtPath:dst]) {
                [self appendLog:[NSString stringWithFormat:@"[✓] %@ installed", [src lastPathComponent]]];
                
                // Set permissions for dylib
                if ([dst hasSuffix:@".dylib"]) {
                    [self runSudoCommand:@"chmod" args:@[@"755", dst]];
                    [self appendLog:[NSString stringWithFormat:@"[*] Set permissions 755 on %@", [dst lastPathComponent]]];
                }
            } else {
                [self appendLog:[NSString stringWithFormat:@"[!] Failed to copy %@", [src lastPathComponent]]];
                allSuccess = NO;
            }
            
            // Update progress
            dispatch_async(dispatch_get_main_queue(), ^{
                lib.downloadProgress = (float)(i + 1) / (float)lib.filesToCopy.count;
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            lib.isDownloading = NO;
            lib.isInstalled = allSuccess;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            
            if (allSuccess) {
                [self appendLog:[NSString stringWithFormat:@"[✓] %@ installed successfully!", lib.name]];
            } else {
                [self appendLog:[NSString stringWithFormat:@"[!] %@ installation had errors. Check log above.", lib.name]];
            }
        });
    });
}

// ============================================================================
// MARK: - NSURLSession Download Delegate (for dpkg method)
// ============================================================================

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location {
    NSNumber *idxNum = self.activeDownloads[@(downloadTask.taskIdentifier).stringValue];
    if (!idxNum) return;
    NSInteger idx = [idxNum integerValue];
    LibraryInfo *lib = self.libraries[idx];
    
    // Move to a temp location
    NSString *tempDeb = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.deb", lib.name, lib.versions[lib.selectedVersionIndex]]];
    [[NSFileManager defaultManager] removeItemAtPath:tempDeb error:nil];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:tempDeb] error:&error];
    
    if (error) {
        [self appendLog:[NSString stringWithFormat:@"[!] File move error: %@", error.localizedDescription]];
        lib.isDownloading = NO;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    
    [self appendLog:[NSString stringWithFormat:@"[✓] Downloaded to %@", tempDeb]];
    [self appendLog:@"[*] Running dpkg -i ..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self runSudoCommand:@"dpkg" args:@[@"-i", tempDeb]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            lib.isDownloading = NO;
            lib.isInstalled = YES;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [self appendLog:[NSString stringWithFormat:@"[✓] %@ installed successfully!", lib.name]];
        });
    });
    
    [self.activeDownloads removeObjectForKey:@(downloadTask.taskIdentifier).stringValue];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSNumber *idxNum = self.activeDownloads[@(downloadTask.taskIdentifier).stringValue];
    if (!idxNum) return;
    NSInteger idx = [idxNum integerValue];
    LibraryInfo *lib = self.libraries[idx];
    
    if (totalBytesExpectedToWrite > 0) {
        lib.downloadProgress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) return;
    
    NSNumber *idxNum = self.activeDownloads[@(task.taskIdentifier).stringValue];
    if (!idxNum) return;
    NSInteger idx = [idxNum integerValue];
    LibraryInfo *lib = self.libraries[idx];
    
    lib.isDownloading = NO;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self appendLog:[NSString stringWithFormat:@"[!] Download failed: %@", error.localizedDescription]];
    
    [self.activeDownloads removeObjectForKey:@(task.taskIdentifier).stringValue];
}

// ============================================================================
// MARK: - Command Execution
// ============================================================================

- (void)appendLog:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logTextView.text = [self.logTextView.text stringByAppendingFormat:@"%@\n", text];
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    });
}

- (NSString *)runSudoCommand:(NSString *)command args:(NSArray<NSString *> *)args {
    // Wraps command through sudo for root privileges, providing the cached mobile password
    NSString *safePwd = [self.sudoPassword stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    // Explicitly set PATH for the sudo session and use env so commands like dpkg, rm, cp are resolved correctly
    NSMutableString *fullCommand = [NSMutableString stringWithFormat:@"printf '%%s\\n' \"%@\" | /var/jb/usr/bin/sudo -S /var/jb/usr/bin/env PATH=\"/var/jb/usr/local/bin:/var/jb/usr/bin:/var/jb/usr/sbin:/var/jb/bin:/var/jb/sbin\" ", safePwd ? safePwd : @"alpine"];
    
    [fullCommand appendString:command];
    for (NSString *arg in args) {
        [fullCommand appendFormat:@" \"%@\"", arg];
    }
    return [self runCommand:@"/var/jb/bin/sh" args:@[@"-c", fullCommand]];
}

- (NSString *)runCommand:(NSString *)command args:(NSArray<NSString *> *)args {
    pid_t pid;
    int status;
    
    int pipefd[2];
    pipe(pipefd);
    
    posix_spawn_file_actions_t file_actions;
    posix_spawn_file_actions_init(&file_actions);
    posix_spawn_file_actions_adddup2(&file_actions, pipefd[1], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&file_actions, pipefd[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&file_actions, pipefd[0]);
    
    const char *cmd = [command UTF8String];
    NSUInteger totalArgs = args.count + 2;
    char **argv = (char **)calloc(totalArgs, sizeof(char *));
    argv[0] = (char *)cmd;
    for (NSUInteger i = 0; i < args.count; i++) {
        argv[i + 1] = (char *)[args[i] UTF8String];
    }
    argv[args.count + 1] = NULL;
    
    int ret = posix_spawn(&pid, cmd, &file_actions, NULL, argv, environ);
    posix_spawn_file_actions_destroy(&file_actions);
    free(argv);
    
    if (ret != 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        return [NSString stringWithFormat:@"Error spawning process: %d", ret];
    }
    
    close(pipefd[1]);
    
    NSMutableData *outputData = [NSMutableData data];
    char buffer[1024];
    ssize_t bytesRead;
    while ((bytesRead = read(pipefd[0], buffer, sizeof(buffer))) > 0) {
        [outputData appendBytes:buffer length:bytesRead];
        NSString *str = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
        if (str) {
            [self appendLog:str];
        }
    }
    close(pipefd[0]);
    
    waitpid(pid, &status, 0);
    [self appendLog:[NSString stringWithFormat:@"[*] Process exit code: %d", WEXITSTATUS(status)]];
    
    return [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
}

// ============================================================================
// MARK: - Respring
// ============================================================================

- (void)respringTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Respring"
                                                                   message:@"Are you sure you want to respring the device?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self appendLog:@"\n[*] Respringing device..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self runCommand:@"/var/jb/usr/bin/sbreload" args:@[]];
        });
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
