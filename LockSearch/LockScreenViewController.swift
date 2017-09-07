/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

// image by NASA: https://www.flickr.com/photos/nasacommons/29193068676/

import UIKit

class LockScreenViewController: UIViewController {

  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var dateTopConstraint: NSLayoutConstraint!

  let blurView = UIVisualEffectView(effect: nil)

  var settingsController: SettingsViewController!
  var startFrame: CGRect?
  var previewView: UIView?
  var previewAnimator: UIViewPropertyAnimator?
  let previewEffectView = IconEffectView(blur: .extraLight)
  let presentTransition = PresentTransition()
  var isDragging = false
  var isPresentingSettings = false
  var touchesStartPointY: CGFloat?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.bringSubview(toFront: searchBar)
    blurView.isUserInteractionEnabled = false
    view.insertSubview(blurView, belowSubview: searchBar)

    tableView.estimatedRowHeight = 130.0
    tableView.rowHeight = UITableViewAutomaticDimension
  }

  override func viewWillLayoutSubviews() {
    blurView.frame = view.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    tableView.transform = CGAffineTransform.init(scaleX: 0.67, y: 0.67)
    tableView.alpha = 0
    dateTopConstraint.constant -= 100
    view.layoutIfNeeded()
    //scale.startAnimation()
  }

  override func viewDidAppear(_ animated: Bool) {
    
    AnimatorFactory.scaleUp(view: tableView).startAnimation()
    AnimatorFactory.animateConstraint(view: view, constraint: dateTopConstraint, by: 100).startAnimation()
  }

  func toggleBlur(_ blurred: Bool) {
    UIViewPropertyAnimator(duration: 0.55, controlPoint1: CGPoint(x: 0.57, y: -0.4), controlPoint2: CGPoint(x: 0.96, y: 0.87), animations: blurAnimations(blurred)).startAnimation()
  }
  
  func blurAnimations(_ blurred: Bool) -> () -> Void {
    return {
      self.blurView.effect = blurred ? UIBlurEffect(style: .dark) : nil
      self.tableView.transform = blurred ? CGAffineTransform(scaleX: 0.75, y: 0.75) : .identity
      self.tableView.alpha = blurred ? 0.33 : 1.0
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    guard presentTransition.wantsInteractiveStart == false,
     let _ = presentTransition.animator else {
      return
    }
    
    touchesStartPointY = touches.first!.location(in: view).y
    presentTransition.interruptTransition()
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    
  }

  @IBAction func presentSettings(_ sender: Any? = nil) {
    //present the view controller
    presentTransition.auxAnimations = blurAnimations(true)
    presentTransition.auxAnimationsCancel = blurAnimations(false)
    settingsController = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
    settingsController.transitioningDelegate = self
    settingsController.didDismiss = { [unowned self] in
      self.toggleBlur(false)
    }
    present(settingsController, animated: true, completion: nil)
  }
  
}

extension LockScreenViewController: UISearchBarDelegate {
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    toggleBlur(true)
  }
  
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    toggleBlur(false)
  }
  
  func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText.isEmpty {
      searchBar.resignFirstResponder()
    }
  }
}

extension LockScreenViewController: WidgetsOwnerProtocol {
    
    func startPreview(for forView: UIView) {
        previewView?.removeFromSuperview()
        previewView = forView.snapshotView(afterScreenUpdates: false)
        view.insertSubview(previewView!, aboveSubview: blurView)
        
        previewView?.frame = forView.convert(forView.bounds, to: view)
        startFrame = previewView?.frame
        addEffectView(below: previewView!)
      
        previewAnimator = AnimatorFactory.grow(view: previewEffectView, blurView: blurView)
    }
    
    func addEffectView(below forView: UIView) {
        previewEffectView.removeFromSuperview()
        previewEffectView.frame = forView.frame
        
        forView.superview?.insertSubview(previewEffectView, belowSubview: forView)
    }
    
    func updatePreview(percent: CGFloat) {
        previewAnimator?.fractionComplete = max(0.01, min(0.99, percent))
    }
  
  func cancelPreview() {
    if let previewAnimator = previewAnimator {
      previewAnimator.isReversed = true
      previewAnimator.startAnimation()
      
      previewAnimator.addCompletion { position in
        switch position {
          case .start:
            self.previewView?.removeFromSuperview()
            self.previewEffectView.removeFromSuperview()
          default: break
          }
        }
    }
  }
  
  func finishPreview() {
    
    previewAnimator?.stopAnimation(false)
    previewAnimator?.finishAnimation(at: .end)
    previewAnimator = nil
    
    AnimatorFactory.complete(view: previewEffectView).startAnimation()
  }
}

extension LockScreenViewController: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row == 1 {
      let cell = tableView.dequeueReusableCell(withIdentifier: "Footer") as! FooterCell
      cell.didPressEdit = {[unowned self] in
        self.presentTransition.wantsInteractiveStart = false
        self.presentSettings()
      }
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! WidgetCell
      cell.tableView = tableView
      cell.owner = self
      return cell
    }
  }
}

extension LockScreenViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentTransition
    }
  
  func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    
    return presentTransition
  }
}

extension LockScreenViewController: UIScrollViewDelegate {
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    
    isDragging = true
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    guard isDragging else {
        return
    }
    
    if !isPresentingSettings && scrollView.contentOffset.y < -30 {
        isPresentingSettings = true
        presentTransition.wantsInteractiveStart = true
        presentSettings()
        return
    }
    
    if isPresentingSettings {
        let progress = max(0.0, min(1.0, ((-scrollView.contentOffset.y) - 30) / 90.0))
        presentTransition.update(progress)
    }
  }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let progress = max(0.0, min(1.0, ((-scrollView.contentOffset.y) - 30) / 90.0))
        
        if progress > 0.5 {
            presentTransition.finish()
        } else {
            presentTransition.cancel()
        }
        
        isPresentingSettings = false
        isDragging = false
    }
}
