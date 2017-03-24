//
//  ViewController.m
//  iTaggingText
//
//  Created by Rajesh Thangaraj on 18/03/17.
//  Copyright © 2017 Rajesh Thangaraj. All rights reserved.
//

#import "ViewController.h"

@interface TableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;

@end

@implementation TableViewCell

@end

@interface ViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (strong, nonatomic) NSMutableArray *array;
@property (strong, nonatomic) NSMutableArray *dateArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_tableview setRowHeight:UITableViewAutomaticDimension];
    [_tableview setEstimatedRowHeight:44];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [_textView becomeFirstResponder];
}


- (void)keyboardWillShow:(NSNotification *)notification {
    [self adjustTextViewByKeyboardState:YES keyboardInfo:[notification userInfo]];
}


- (void)adjustTextViewByKeyboardState:(BOOL)showKeyboard keyboardInfo:(NSDictionary *)info {
    [_bottomConstraint setConstant:256.f];
    UIViewAnimationCurve animationCurve = [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
    if (animationCurve == UIViewAnimationCurveEaseIn) {
        animationOptions |= UIViewAnimationOptionCurveEaseIn;
    }
    else if (animationCurve == UIViewAnimationCurveEaseInOut) {
        animationOptions |= UIViewAnimationOptionCurveEaseInOut;
    }
    else if (animationCurve == UIViewAnimationCurveEaseOut) {
        animationOptions |= UIViewAnimationOptionCurveEaseOut;
    }
    else if (animationCurve == UIViewAnimationCurveLinear) {
        animationOptions |= UIViewAnimationOptionCurveLinear;
    }
    [UIView animateWithDuration:[[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] delay:0 options:animationOptions animations:^{
        [self.view layoutIfNeeded];
    }                completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSMutableArray *)array {
    if (_array == nil) {
        _array = [[NSMutableArray alloc] init];
    }
    return _array;
}

- (NSMutableArray *)dateArray {
    if (_dateArray == nil) {
        _dateArray = [[NSMutableArray alloc] init];
    }
    return _dateArray;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:indexPath.row % 2 == 1 ? @"TableViewCellOther" : @"TableViewCellMe"  forIndexPath:indexPath];
    [tableViewCell.textView setAttributedText:_array[indexPath.row]];
    [tableViewCell.dateLabel setText:[_dateArray objectAtIndex:indexPath.row]];
    return tableViewCell;
}

- (IBAction)sendAction:(id)sender {
    NSMutableParagraphStyle *paragraphStyle = nil;
    if (_array.count %2 == 0) {
        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentRight;
    }
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.attributedText];
    [_textView.attributedText enumerateAttribute:NSBackgroundColorAttributeName inRange:NSMakeRange(0, _textView.attributedText.string.length) options:NSAttributedStringEnumerationReverse usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if (value) {
            [attributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor cyanColor] range:range];
        }
    }];
    if (paragraphStyle) {
        [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, _textView.attributedText.string.length)];
    }
    [[self array] addObject:attributedText];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [[self dateArray] addObject:[dateFormatter stringFromDate:[NSDate date]]];
    [self.tableview reloadData];
 
    NSMutableAttributedString *resetText = [[NSMutableAttributedString alloc] initWithString:@" "];
    [resetText addAttribute:NSFontAttributeName value:_textView.font range:NSMakeRange(0, 1)];
    _textView.attributedText = resetText;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _textView.attributedText = nil;
    });
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (text.length == 0) {
        NSString * firstHalfString = [textView.text substringToIndex:range.location];
        NSMutableArray *array = [[firstHalfString componentsSeparatedByString:@" "] mutableCopy];
        NSRange edittingWordRange = [firstHalfString rangeOfString:[array lastObject] options:NSBackwardsSearch];
        
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
        [attributedText enumerateAttribute:NSBackgroundColorAttributeName inRange:edittingWordRange options:NSAttributedStringEnumerationReverse usingBlock:^(id  _Nullable attvalue, NSRange attrange, BOOL * _Nonnull stop) {
            if (attvalue) {
                [attributedText removeAttribute:NSBackgroundColorAttributeName range:edittingWordRange];
                [textView setAttributedText:attributedText];
                textView.selectedRange = NSMakeRange(range.location + 1, 0);
            }
        }];
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    NSRange range = _textView.selectedRange;
    NSString * firstHalfString = [_textView.text substringToIndex:range.location];
    NSMutableArray *array = [[firstHalfString componentsSeparatedByString:@" "] mutableCopy];
    NSString *edittingWord = [[array lastObject] lowercaseString];
    edittingWord = [edittingWord lowercaseString];
    if ([edittingWord hasPrefix:@"abcd"]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Choose from library" preferredStyle:UIAlertControllerStyleActionSheet];
        [self presentViewController:alertController animated:YES completion:nil];
        [alertController addAction:[UIAlertAction actionWithTitle:@"abcd" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self replaceString:action.title];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    } else if ([edittingWord hasPrefix:@"abc"]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Choose from" preferredStyle:UIAlertControllerStyleActionSheet];
        [self presentViewController:alertController animated:YES completion:nil];
        [alertController addAction:[UIAlertAction actionWithTitle:@"abc" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self replaceString:action.title];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"abcd" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self replaceString:action.title];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
    } else if ([edittingWord hasPrefix:@"ab"]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Choose from" preferredStyle:UIAlertControllerStyleActionSheet];
        [self presentViewController:alertController animated:YES completion:nil];
        [alertController addAction:[UIAlertAction actionWithTitle:@"ab" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self replaceString:action.title];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"abc" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self replaceString:action.title];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"abcd" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self replaceString:action.title];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    }
}

- (void)replaceString:(NSString *)string {
    NSRange range = _textView.selectedRange;
    NSString * firstHalfString = [_textView.text substringToIndex:range.location];
    NSMutableArray *array = [[firstHalfString componentsSeparatedByString:@" "] mutableCopy];
    NSString *edittingWord = [array lastObject];
    [array removeObject:edittingWord];
    range = [firstHalfString rangeOfString:edittingWord options:NSBackwardsSearch];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.attributedText];
    [attributedText replaceCharactersInRange:range withString:[string stringByAppendingString:@" "]];
    range.length = string.length;
    [attributedText addAttributes:@{NSBackgroundColorAttributeName : [UIColor lightGrayColor]} range:range];
    [_textView setAttributedText:attributedText];
    range.location = range.location + string.length + 1;
    range.length = 0;
    _textView.selectedRange = range;
}

@end
