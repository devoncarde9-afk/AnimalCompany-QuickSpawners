#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

@interface ModMenuController : UIViewController
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *contentScrollView;
- (void)loadItemsTab;
@end

extern void SpawnItem(void *itemName, int quantity, float x, float y, float z, int colorHue, int colorSat);
extern void* il2cpp_string_new(const char *str);

static void spawn(NSString *item, int qty) {
    void *str = il2cpp_string_new([item UTF8String]);
    SpawnItem(str, qty, 0, 0, 0, 0, 0);
}

static void spawnLater(NSString *item, int qty, double delay) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ spawn(item, qty); });
}

static const void *kInjected = &kInjected;

%hook ModMenuController

- (void)loadItemsTab {
    %orig;
    
    if (objc_getAssociatedObject(self, kInjected)) return;
    objc_setAssociatedObject(self, kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self addQuickSpawners];
    });
}

%new
- (void)addQuickSpawners {
    UIView *cv = self.contentView;
    if (!cv) return;
    
    CGFloat W = cv.bounds.size.width;
    if (W <= 0) W = UIScreen.mainScreen.bounds.size.width - 40;
    
    CGFloat y = 0;
    for (UIView *sub in cv.subviews) {
        CGFloat maxY = CGRectGetMaxY(sub.frame);
        if (maxY > y) y = maxY;
    }
    y += 20;
    
    CGFloat pad = 15, bH = 50;
    
    // Divider
    UIView *div = [[UIView alloc] initWithFrame:CGRectMake(pad, y, W-pad*2, 1)];
    div.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    [cv addSubview:div];
    y += 12;
    
    // Header
    UILabel *hdr = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, W-pad*2, 36)];
    hdr.text = @"⚡ QUICK SPAWNERS";
    hdr.textColor = [UIColor whiteColor];
    hdr.font = [UIFont boldSystemFontOfSize:16];
    hdr.textAlignment = NSTextAlignmentCenter;
    hdr.backgroundColor = [UIColor colorWithRed:0.12 green:0.2 blue:0.35 alpha:0.95];
    hdr.layer.cornerRadius = 8;
    hdr.clipsToBounds = YES;
    [cv addSubview:hdr];
    y += 42;
    
    // JSON Spawner button
    UIButton *jsonBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    jsonBtn.frame = CGRectMake(pad, y, W-pad*2, bH);
    jsonBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.9 alpha:1];
    [jsonBtn setTitle:@"📄 JSON Spawner" forState:UIControlStateNormal];
    [jsonBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    jsonBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    jsonBtn.layer.cornerRadius = 10;
    jsonBtn.clipsToBounds = YES;
    [jsonBtn addTarget:self action:@selector(openJSON) forControlEvents:UIControlEventTouchUpInside];
    [cv addSubview:jsonBtn];
    y += bH + 10;
    
    // All Bags button
    UIButton *bagsBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    bagsBtn.frame = CGRectMake(pad, y, W-pad*2, bH);
    bagsBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.3 blue:0.7 alpha:1];
    [bagsBtn setTitle:@"🎒 All Bags (17 types)" forState:UIControlStateNormal];
    [bagsBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    bagsBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    bagsBtn.layer.cornerRadius = 10;
    bagsBtn.clipsToBounds = YES;
    [bagsBtn addTarget:self action:@selector(spawnAllBags) forControlEvents:UIControlEventTouchUpInside];
    [cv addSubview:bagsBtn];
    y += bH + 10;
    
    // Full Shredder button
    UIButton *shredBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    shredBtn.frame = CGRectMake(pad, y, W-pad*2, bH);
    shredBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.1 alpha:1];
    [shredBtn setTitle:@"💥 Full Shredder (100x)" forState:UIControlStateNormal];
    [shredBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    shredBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    shredBtn.layer.cornerRadius = 10;
    shredBtn.clipsToBounds = YES;
    [shredBtn addTarget:self action:@selector(fullShredder) forControlEvents:UIControlEventTouchUpInside];
    [cv addSubview:shredBtn];
    y += bH + 25;
    
    if (self.contentScrollView) {
        CGFloat newH = MAX(y, self.contentScrollView.contentSize.height);
        self.contentScrollView.contentSize = CGSizeMake(W, newH);
    }
}

%new
- (void)openJSON {
    UIAlertController *a = [UIAlertController 
        alertControllerWithTitle:@"📄 JSON Spawner" 
        message:@"Paste JSON array:\n[{\"item\":\"item_name\",\"qty\":5}]" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.placeholder = @"[{\"item\":\"item_shotgun\",\"qty\":3}]";
        f.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    
    [a addAction:[UIAlertAction actionWithTitle:@"Spawn Items" 
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            NSString *json = a.textFields[0].text;
            if (!json.length) return;
            
            NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err = nil;
            id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            
            if (err || ![obj isKindOfClass:[NSArray class]]) {
                UIAlertController *e = [UIAlertController 
                    alertControllerWithTitle:@"Error" 
                    message:@"Invalid JSON format!\nUse: [{\"item\":\"...\",\"qty\":5}]" 
                    preferredStyle:UIAlertControllerStyleAlert];
                [e addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:e animated:YES completion:nil];
                return;
            }
            
            NSArray *items = (NSArray *)obj;
            for (NSInteger i = 0; i < items.count; i++) {
                NSDictionary *d = items[i];
                NSString *item = d[@"item"];
                NSInteger qty = [d[@"qty"] integerValue] ?: 1;
                if (item) spawnLater(item, qty, i * 0.1);
            }
            
            UIAlertController *ok = [UIAlertController 
                alertControllerWithTitle:@"✅ Spawning" 
                message:[NSString stringWithFormat:@"Spawning %lu items!", (unsigned long)items.count]
                preferredStyle:UIAlertControllerStyleAlert];
            [ok addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:ok animated:YES completion:nil];
    }]];
    
    [a addAction:[UIAlertAction actionWithTitle:@"Example" 
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            NSString *ex = @"[{\"item\":\"item_shotgun\",\"qty\":3},{\"item\":\"item_rpg\",\"qty\":2}]";
            NSData *data = [ex dataUsingEncoding:NSUTF8StringEncoding];
            NSArray *items = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            for (NSInteger i = 0; i < items.count; i++) {
                NSDictionary *d = items[i];
                spawnLater(d[@"item"], [d[@"qty"] integerValue], i * 0.1);
            }
    }]];
    
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" 
        style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:a animated:YES completion:nil];
}

%new
- (void)spawnAllBags {
    NSArray *bags = @[
        @"item_backpack", @"item_backpack_big", @"item_backpack_black", @"item_backpack_cube",
        @"item_backpack_gold", @"item_backpack_green", @"item_backpack_large_base",
        @"item_backpack_large_basketball", @"item_backpack_large_clover", @"item_backpack_mega",
        @"item_backpack_neon", @"item_backpack_pink", @"item_backpack_realistic",
        @"item_backpack_skull", @"item_backpack_small_base", @"item_backpack_white",
        @"item_backpack_with_flashlight"
    ];
    
    for (NSInteger i = 0; i < bags.count; i++) {
        spawnLater(bags[i], 1, i * 0.08);
    }
}

%new
- (void)fullShredder {
    for (int i = 0; i < 100; i++) {
        spawnLater(@"item_shredder", 1, i * 0.05);
    }
}

%end
