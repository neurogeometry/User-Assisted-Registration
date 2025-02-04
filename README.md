**User Assisted Registration** is software for a user-assisted approach for accurate nonrigid registration of images, traces, and point sets in 2- and 3-D, developed by the Neurogeometry lab. This software was created by utilizing the framework used in [BoutonAnalyzer]( https://github.com/neurogeometry/BoutonAnalyzer) The related publication for this repository:

#### [User-Assisted Approach for Accurate Nonrigid Registration of Traces and Images]( https://www.biorxiv.org/content/10.1101/2025.01.29.635549v1)
>*Abstact:* . Fully automated registration algorithms are prone to getting trapped in solutions corresponding to local minima of their objective functions, leading to errors that are easy to detect but challenging to correct. Traditional solutions often involve iterative parameter tuning, data preprocessing and preregistering, and multiple algorithm reruns – an approach that is both time-consuming and does not guarantee satisfactory results. Therefore, for tasks where registration accuracy is more important than speed, it is appropriate to explore alternative, user-assisted registration strategies. In such tasks, finding and correcting errors in automated registration is often more time-consuming than directly integrating user input during the registration process.
Therefore, this study evaluates a user-assisted approach for accurate nonrigid registration of images and traces. By leveraging the corresponding sets of fiducial points provided by the user to guide the registration, the algorithm computes an optimal nonrigid transformation that combines linear and nonlinear components. Our findings demonstrate that the registration accuracy of this approach improves consistently with the increased complexity of the linear transformation and as more fiducial points are provided. As a result, accuracy sufficient for many biomedical applications can be achieved within minutes, requiring only a small number of user-provided fiducial points.

### Requirements ###

* MATLAB for Mac or Windows, version 2024a or higher

### Installation ###

* Download/clone the repository
* Launch MATLAB and navigate to the software folder
* Run `Registration_GUI.m`
* Set paths to the images, traces, or point sets in the User-Assisted Registration main window
### Sample Data ###
* SampleData folder includes four types of sample datasets for 2D  image, 3D image, trace, and point set registration.

* 2D image data is taken from Category A for the FIRE: Fundus Image Registration Dataset. The complete dataset can be found [here]( https://projects.ics.forth.gr/cvrl/fire/). We include two images from this dataset that come in .jpg and .mat files

* 3D image data includes confocal microscope image stacks of FLP neurons in two C. elegans [related publication](). The images were cropped to focus on the cell bodies of these neurons and saved in 3D tiff file format.

* Trace data is based on the FLP neuron images from the [related publication]( https://www.biorxiv.org/content/10.1101/2025.01.29.635549v1). The images were manually traced in 3D using [NCTracer](https://neurogeometry.sites.northeastern.edu/neural-circuit-tracer/ ). Traces of FLP neurons from two C. elegans of the same age are provided in .swc format.

* Point set data was obtained from [here](https://github.com/bing-jian/gmmreg). It is associated with [“Robust Point Set Registration Using Gaussian Mixture Models” by B. Jian, B. Vemuri](https://ieeexplore.ieee.org/document/5674050).

### Contact ###

* Junaid Baig baig.mi@northeastern.edu.
* Armen Stepanyants a.stepanyants@northeastern.edu
