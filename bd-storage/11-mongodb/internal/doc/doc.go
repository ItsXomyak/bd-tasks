package doc

type Checkout struct {
	Year         int    `bson:"year"`
	Month        int    `bson:"month"`
	MaterialType string `bson:"material_type"`
	Count        int    `bson:"count"`
}

type Title struct {
	Title     string     `bson:"title"`
	Creator   string     `bson:"creator,omitempty"`
	Publisher string     `bson:"publisher,omitempty"`
	Subjects  []string   `bson:"subjects"`
	Checkouts []Checkout `bson:"checkouts"`
}
