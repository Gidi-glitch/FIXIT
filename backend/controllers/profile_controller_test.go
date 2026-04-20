package controllers

import (
	"reflect"
	"testing"
)

func TestSyncServiceAreasWithNewHomeBarangay_ReplacesOldHomeBarangay(t *testing.T) {
	got := syncServiceAreasWithNewHomeBarangay(
		`["Dayap","Imok","Masiit"]`,
		"Dayap",
		"Hanggan",
	)

	want := []string{"Hanggan", "Imok", "Masiit"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("unexpected service areas\nwant: %#v\ngot:  %#v", want, got)
	}
}

func TestSyncServiceAreasWithNewHomeBarangay_AppendsWhenOldMissing(t *testing.T) {
	got := syncServiceAreasWithNewHomeBarangay(
		`["Imok","Masiit"]`,
		"Dayap",
		"Hanggan",
	)

	want := []string{"Imok", "Masiit", "Hanggan"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("unexpected service areas\nwant: %#v\ngot:  %#v", want, got)
	}
}

func TestSyncServiceAreasWithNewHomeBarangay_UsesPreviousWhenEmptyList(t *testing.T) {
	got := syncServiceAreasWithNewHomeBarangay(
		"",
		"Dayap",
		"Hanggan",
	)

	want := []string{"Hanggan"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("unexpected service areas\nwant: %#v\ngot:  %#v", want, got)
	}
}
